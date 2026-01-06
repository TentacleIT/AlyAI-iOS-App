import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

struct CachedDailyPlan: Codable {
    let date: Date
    let mood: String
    let phase: String
    let plan: DailyMealPlan
}

struct MealHistoryItem: Codable {
    let date: String
    let breakfast: String
    let lunch: String
    let dinner: String
}

class NutritionManager: ObservableObject {
    static let shared = NutritionManager()
    
    @Published var currentPlan: DailyMealPlan?
    @Published var preferences: NutritionPreferences = NutritionPreferences()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let cacheKey = "daily_meal_plan_cache"
    private let historyUserDefaultsKey = "meal_history_log"
    private var db = Firestore.firestore()
    
    private var mealHistory: [MealHistoryItem] = []
    
    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if user != nil {
                self?.loadPreferences()
                self?.loadHistory()
                self?.loadCachedPlan()
            } else {
                self?.mealHistory = []
                self?.currentPlan = nil
                self?.preferences = NutritionPreferences()
            }
        }
    }
    
    // MARK: - Preferences Management
    
    func loadPreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let docRef = db.collection("users").document(uid).collection("nutrition").document("preferences")
        
        docRef.getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                if let prefs = try? document.data(as: NutritionPreferences.self) {
                    DispatchQueue.main.async {
                        self?.preferences = prefs
                    }
                }
            } else {
                // Initialize defaults from UserProfile if available
                self?.initializeDefaultPreferences()
            }
        }
    }
    
    func savePreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        preferences.lastUpdated = Date()
        
        do {
            try db.collection("users").document(uid).collection("nutrition").document("preferences").setData(from: preferences)
        } catch {
            print("Error saving nutrition preferences: \(error)")
        }
    }
    
    private func initializeDefaultPreferences() {
        if let profile = UserProfileManager.shared.currentUserProfile {
            let answers = profile.userAnswers
            let country = (answers["country"] as? String) ?? "Global"
            let diet = (answers["dietary_preference"] as? String) ?? "Balanced"
            let allergies = (answers["allergies"] as? [String]) ?? []
            
            let newPrefs = NutritionPreferences(country: country, dietType: diet, allergies: allergies)
            DispatchQueue.main.async {
                self.preferences = newPrefs
            }
            // Save initialized preferences
            savePreferences()
        }
    }
    
    // MARK: - History & Caching
    
    private func loadHistory() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).collection("mealHistory").order(by: "date", descending: true).limit(to: 14).getDocuments { [weak self] (querySnapshot, err) in
            if let err = err {
                print("Error getting meal history: \(err)")
                return
            }
            guard let documents = querySnapshot?.documents else { return }
            self?.mealHistory = documents.compactMap { queryDocumentSnapshot -> MealHistoryItem? in
                return try? queryDocumentSnapshot.data(as: MealHistoryItem.self)
            }
        }
    }
    
    func loadLegacyHistory() -> [MealHistoryItem]? {
        guard let data = UserDefaults.standard.data(forKey: historyUserDefaultsKey) else { return nil }
        return try? JSONDecoder().decode([MealHistoryItem].self, from: data)
    }

    private func addToHistory(_ plan: DailyMealPlan) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let item = MealHistoryItem(
            date: plan.date,
            breakfast: plan.meals.breakfast.title,
            lunch: plan.meals.lunch.title,
            dinner: plan.meals.dinner.title
        )

        do {
            // Save to legacy history path
            try db.collection("users").document(uid).collection("mealHistory").document(plan.date).setData(from: item)
            
            // Save full plan to new schema path
            try db.collection("users").document(uid).collection("nutrition").document("generatedMeals").collection("history").document(plan.date).setData(from: plan)
            
            // Prepend to local history to keep it up to date
            self.mealHistory.insert(item, at: 0)
            if self.mealHistory.count > 14 {
                self.mealHistory.removeLast()
            }
        } catch {
            print("Error saving meal history item: \(error)")
        }
    }
    
    func loadCachedPlan() {
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let cached = try? JSONDecoder().decode(CachedDailyPlan.self, from: data) {
            
            if Calendar.current.isDateInToday(cached.date) {
                let currentMood = getCurrentMood()
                let currentPhase = CycleManager.shared.currentPhase.rawValue
                
                if cached.mood == currentMood && cached.phase == currentPhase {
                    self.currentPlan = cached.plan
                    return
                }
            }
        }
        
        generateDailyPlan()
    }
    
    func refreshPlan() {
        generateDailyPlan()
    }

    private func saveImageToDisk(data: Data, filename: String) -> String? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url.absoluteString
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // MARK: - Generation Logic
    
    private func generateDailyPlan() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        let context = gatherContext()
        let prompt = buildPrompt(context: context)
        
        OpenAIService.shared.runAssessment(prompt: prompt, jsonMode: true) { [weak self] response in
            guard let self = self else { return }
            
            guard let data = response.data(using: .utf8),
                  var plan = try? JSONDecoder().decode(DailyMealPlan.self, from: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to generate meal plan. Please try again."
                }
                return
            }
            
            // Populate metadata
            plan.countryUsed = self.preferences.country
            plan.cyclePhase = context["cyclePhase"]
            plan.moodContext = context["currentMood"]
            plan.symptomsConsidered = (context["symptoms"] ?? "").components(separatedBy: ", ").filter { !$0.isEmpty }
            
            // Image Generation
            let group = DispatchGroup()
            
            group.enter()
            self.generateImageForMeal(prompt: plan.meals.breakfast.imagePrompt, suffix: "breakfast") { path in
                plan.meals.breakfast.imageUrl = path
                group.leave()
            }
            
            group.enter()
            self.generateImageForMeal(prompt: plan.meals.lunch.imagePrompt, suffix: "lunch") { path in
                plan.meals.lunch.imageUrl = path
                group.leave()
            }
            
            group.enter()
            self.generateImageForMeal(prompt: plan.meals.dinner.imagePrompt, suffix: "dinner") { path in
                plan.meals.dinner.imageUrl = path
                group.leave()
            }
            
            group.notify(queue: .main) {
                self.isLoading = false
                self.currentPlan = plan
                self.cachePlan(plan)
                self.addToHistory(plan)
            }
        }
    }
    
    private func generateImageForMeal(prompt: String, suffix: String, completion: @escaping (String?) -> Void) {
        OpenAIService.shared.generateImage(prompt: prompt) { urlStr in
            if let urlStr = urlStr, let url = URL(string: urlStr) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let path = self.saveImageToDisk(data: data, filename: "\(suffix)_\(Date().timeIntervalSince1970).jpg") {
                        completion(path)
                    } else {
                        completion(nil)
                    }
                }.resume()
            } else {
                completion(nil)
            }
        }
    }
    
    private func cachePlan(_ plan: DailyMealPlan) {
        let currentMood = getCurrentMood()
        let currentPhase = CycleManager.shared.currentPhase.rawValue
        
        let cached = CachedDailyPlan(date: Date(), mood: currentMood, phase: currentPhase, plan: plan)
        
        if let encoded = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    func getCurrentMood() -> String {
        if let log = CycleManager.shared.todayLog, let mood = log.mood.state?.rawValue {
            return mood
        }
        return "Stable"
    }
    
    private func calculateTrends() -> (mood: String, energy: String) {
        let end = Date()
        guard let start = Calendar.current.date(byAdding: .day, value: -7, to: end) else { return ("Unknown", "Unknown") }
        
        let logs = CycleManager.shared.monthLogs.filter { date, log in
            return date >= start && date <= end
        }
        
        let energies = logs.values.map { $0.energyLevel }
        let energyTrend: String
        if energies.isEmpty {
            energyTrend = "Stable"
        } else {
            let avg = Double(energies.reduce(0, +)) / Double(energies.count)
            energyTrend = "Average \(Int(avg))/10"
        }
        
        let sortedLogs = logs.sorted { $0.key < $1.key }
        let sortedMoods = sortedLogs.compactMap { $0.value.mood.state?.rawValue }
        
        let moodTrend: String
        if sortedMoods.isEmpty {
            moodTrend = "Stable"
        } else {
            let suffix = sortedMoods.suffix(3).joined(separator: " -> ")
            moodTrend = suffix.isEmpty ? "Stable" : suffix
        }
        
        return (moodTrend, energyTrend)
    }
    
    private func getMealHistoryString() -> String {
        guard !mealHistory.isEmpty else { return "None" }
        return mealHistory.map { item in
            "- \(item.date): Breakfast: \(item.breakfast), Lunch: \(item.lunch), Dinner: \(item.dinner)"
        }.joined(separator: "\n")
    }
    
    // MARK: - Cycle Phase Logic
    
    private func getPhaseNutritionFocus(phase: CyclePhase) -> String {
        switch phase {
        case .menstrual:
            return "Focus: Iron replenishment, Anti-inflammatory, Comfort & warmth, Easy digestion. Favor iron-rich foods, soups, warm meals. Reduce salty and bloating-trigger foods."
        case .follicular:
            return "Focus: Energy rebuilding, Light, fresh meals, Brain clarity. Favor lean proteins, fruits, vegetables, lighter meals with fiber."
        case .ovulation:
            return "Focus: Hormone balance, Anti-oxidants, Gut health. Favor colorful vegetables, hydration-supporting foods."
        case .luteal:
            return "Focus: Mood stability, Craving management, Blood sugar balance. Favor complex carbs, magnesium-rich foods. Reduce sugar spikes."
        case .unknown:
            return "Focus: Balanced, nutrient-dense meals for general wellness."
        }
    }
    
    private func gatherContext() -> [String: String] {
        var context: [String: String] = [:]
        
        // Use Preferences as primary source
        context["userCountry"] = preferences.country
        context["dietType"] = preferences.dietType
        context["restrictions"] = preferences.allergies.joined(separator: ", ")
        context["excludedFoods"] = preferences.excludedFoods.joined(separator: ", ")
        
        // Fallback or additional info from Profile
        if let profile = UserProfileManager.shared.currentUserProfile {
            let answers = profile.userAnswers
            context["userName"] = (answers["name"] as? String) ?? "User"
            context["ageRange"] = (answers["age_range"] as? String) ?? "Unknown"
            context["supportAreas"] = (answers["support_areas"] as? [String])?.joined(separator: ", ") ?? "General Wellness"
            context["currentFocus"] = (answers["current_focus"] as? String) ?? "Balance"
        } else {
            context["userName"] = "Friend"
        }
        
        let trends = calculateTrends()
        context["currentMood"] = getCurrentMood()
        context["moodTrend"] = trends.mood
        context["energyTrend"] = trends.energy
        context["mealHistory"] = getMealHistoryString()
        
        // Cycle & Symptoms
        let phase = CycleManager.shared.currentPhase
        context["cyclePhase"] = phase.rawValue
        context["phaseFocus"] = getPhaseNutritionFocus(phase: phase)
        
        if let todayLog = CycleManager.shared.todayLog {
            let symptoms = todayLog.symptoms
            var symptomList: [String] = []
            if symptoms.cramps?.isPresent == true { symptomList.append("Cramps") }
            if symptoms.bloating?.isPresent == true { symptomList.append("Bloating") }
            // Infer fatigue from low energy level
            if todayLog.energyLevel < 4 { symptomList.append("Fatigue / Low Energy") }
            if symptoms.cravings?.isPresent == true { symptomList.append("Cravings") }
            context["symptoms"] = symptomList.joined(separator: ", ")
        }
        
        return context
    }
    
    private func buildPrompt(context: [String: String]) -> String {
        return """
        You are a women’s health nutrition assistant.
        You generate meals based on foods available in the user’s country: \(context["userCountry"]!).
        You adapt nutrition to the user’s menstrual cycle phase: \(context["cyclePhase"]!).
        Your goal is to support hormones, mood, digestion, and energy.
        You prioritize realistic, culturally familiar meals for \(context["userCountry"]!).

        USER CONTEXT:
        - Country: \(context["userCountry"]!)
        - Diet: \(context["dietType"]!)
        - Allergies: \(context["restrictions"]!)
        - Excluded Foods: \(context["excludedFoods"]!)
        - Current Mood: \(context["currentMood"]!)
        - Energy Level: \(context["energyTrend"]!)
        - Recent Symptoms: \(context["symptoms"] ?? "None")

        CYCLE PHASE GUIDANCE (\(context["cyclePhase"]!.uppercased())):
        \(context["phaseFocus"]!)

        INSTRUCTIONS:
        1. Generate healthy meals using foods commonly available in \(context["userCountry"]!).
        2. Adapt meals to support the user’s current menstrual cycle phase (\(context["cyclePhase"]!)).
        3. Consider energy needs, mood, digestion, and hormone balance.
        4. Avoid foods that worsen common symptoms of the current phase (e.g. avoid salty foods if bloating).
        5. If symptoms like Cramps or Fatigue are present, suggest soothing/iron-rich foods.
        6. Do NOT repeat meals from the last 7 days history provided below.

        MEAL HISTORY (LAST 7 DAYS):
        \(context["mealHistory"]!)

        OUTPUT FORMAT (STRICT JSON):
        {
          "date": "YYYY-MM-DD",
          "progressNote": "Explanation of how these meals support the current cycle phase and symptoms.",
          "meals": {
            "breakfast": {
              "title": "",
              "description": "",
              "whyItHelps": "Why this is good for \(context["cyclePhase"]!) phase",
              "howToPrepare": "Brief steps",
              "imagePrompt": "Realistic food photography prompt"
            },
            "lunch": {
              "title": "",
              "description": "",
              "whyItHelps": "",
              "howToPrepare": "",
              "imagePrompt": ""
            },
            "dinner": {
              "title": "",
              "description": "",
              "whyItHelps": "",
              "howToPrepare": "",
              "imagePrompt": ""
            }
          },
          "caloriesEstimate": 2000,
          "countryUsed": "\(context["userCountry"]!)",
          "cyclePhase": "\(context["cyclePhase"]!)"
        }
        """
    }
}
