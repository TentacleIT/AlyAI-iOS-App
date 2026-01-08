import Foundation
import Combine
import FirebaseFirestore

/// Comprehensive user context derived from onboarding answers
/// This ensures all AI responses and recommendations are deeply personalized
@MainActor
class PersonalizationContext: ObservableObject {
    static let shared = PersonalizationContext()
    
    // MARK: - User Demographics
    @Published var userName: String = ""
    @Published var userAge: Int = 0
    @Published var gender: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Primary Goals & Needs
    @Published var primaryGoals: [String] = []
    @Published var greatestNeeds: [String] = []
    @Published var currentFocus: String = ""
    
    // MARK: - Health & Wellness
    @Published var energyLevel: String = ""
    @Published var sleepQuality: String = ""
    @Published var stressLevel: String = ""
    @Published var fitnessLevel: String = ""
    @Published var dietaryPreferences: [String] = []
    @Published var allergies: [String] = []
    
    // MARK: - Cycle Information (if applicable)
    @Published var cyclePhase: String = ""
    @Published var cycleLength: Int = 28
    
    // MARK: - Mental Health
    @Published var mentalHealthConcerns: [String] = []
    @Published var copingStrategies: [String] = []
    @Published var supportSystem: String = ""
    
    // MARK: - Lifestyle
    @Published var workStyle: String = ""
    @Published var activityPreference: String = ""
    @Published var timeAvailable: String = ""
    @Published var country: String = ""
    
    // MARK: - Preferences
    @Published var communicationStyle: String = "warm"
    @Published var learningStyle: String = "visual"
    @Published var motivationType: String = "intrinsic"
    
    // MARK: - Derived Personalization Signals
    @Published var personalityProfile: PersonalityProfile = PersonalityProfile()
    @Published var recommendationTone: String = "supportive"
    @Published var contentComplexity: String = "moderate"
    
    private init() {
        // Listen for profile load events
        UserProfileManager.shared.$isProfileLoaded
            .sink { [weak self] isLoaded in
                if isLoaded {
                    print("📥 Profile loaded, loading PersonalizationContext")
                    Task {
                        await self?.loadFromFirestore()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Try to load immediately if profile is already loaded
        if UserProfileManager.shared.isProfileLoaded {
            Task {
                await loadFromFirestore()
            }
        }
    }
    
    /// Save personalization context to Firestore
    func saveToFirestore() async {
        let data = PersonalizationData(from: self)
        do {
            let encoded = try Firestore.Encoder().encode(data)
            try await FirestoreManager.shared.saveUserData(encoded, in: "personalization", docId: "context")
            print("✅ PersonalizationContext saved to Firestore")
        } catch {
            print("❌ Error saving PersonalizationContext: \(error)")
        }
    }
    
    /// Load personalization context from Firestore
    func loadFromFirestore() async {
        guard let document = await FirestoreManager.shared.fetchUserDocument(from: "personalization", docId: "context") else {
            print("⚠️ No personalization data in Firestore, loading from profile")
            loadFromProfile()
            return
        }
        
        if document.exists {
            do {
                let data = try document.data(as: PersonalizationData.self)
                data.applyTo(context: self)
                print("✅ PersonalizationContext loaded from Firestore")
            } catch {
                print("❌ Error decoding PersonalizationContext: \(error), falling back to profile")
                loadFromProfile()
            }
        } else {
            print("⚠️ Personalization document doesn't exist, loading from profile")
            loadFromProfile()
        }
    }
    
    /// Load personalization context from user profile
    func loadFromProfile() {
        guard let profile = UserProfileManager.shared.currentUserProfile else {
            print("⚠️ No user profile available for personalization")
            return
        }
        
        let answers = profile.userAnswers
        
        // Load demographics
        userName = answers["name"] as? String ?? ""
        gender = answers["gender"] as? String ?? ""
        
        if let dob = answers["dob"] as? Date {
            userAge = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        }
        
        // Load goals and needs
        primaryGoals = answers["main_goal"] as? [String] ?? []
        greatestNeeds = answers["greatest_need"] as? [String] ?? []
        currentFocus = answers["current_focus"] as? String ?? "wellness"
        
        // Load health information
        energyLevel = answers["energy_level"] as? String ?? "moderate"
        sleepQuality = answers["sleep_quality"] as? String ?? "fair"
        stressLevel = answers["stress_level"] as? String ?? "moderate"
        fitnessLevel = answers["fitness_level"] as? String ?? "moderate"
        dietaryPreferences = answers["dietary_preference"] as? [String] ?? []
        allergies = answers["allergies"] as? [String] ?? []
        
        // Load cycle information if female
        if gender.lowercased() == "female" {
            cyclePhase = CycleManager.shared.currentPhase.rawValue
            cycleLength = answers["cycle_length"] as? Int ?? 28
        }
        
        // Load mental health information
        mentalHealthConcerns = answers["mental_health_concerns"] as? [String] ?? []
        copingStrategies = answers["coping_strategies"] as? [String] ?? []
        supportSystem = answers["support_system"] as? String ?? "friends"
        
        // Load lifestyle
        workStyle = answers["work_style"] as? String ?? "flexible"
        activityPreference = answers["activity_preference"] as? String ?? "balanced"
        timeAvailable = answers["time_available"] as? String ?? "moderate"
        country = answers["country"] as? String ?? "Global"
        
        // Load preferences
        communicationStyle = answers["communication_style"] as? String ?? "warm"
        learningStyle = answers["learning_style"] as? String ?? "visual"
        motivationType = answers["motivation_type"] as? String ?? "intrinsic"
        
        // Generate personality profile
        personalityProfile = generatePersonalityProfile(from: answers)
        updateRecommendationTone()
        
        // Save to Firestore after loading from profile
        Task {
            await saveToFirestore()
        }
    }
    
    /// Generate a personality profile based on user answers
    private func generatePersonalityProfile(from answers: [String: Any]) -> PersonalityProfile {
        var profile = PersonalityProfile()
        
        // Determine personality traits based on answers
        let concerns = answers["mental_health_concerns"] as? [String] ?? []
        let needs = answers["greatest_need"] as? [String] ?? []
        
        // Determine if user is more introverted or extroverted
        if needs.contains("Social Connection") || needs.contains("Community") {
            profile.socialPreference = "extroverted"
        } else if needs.contains("Alone Time") || needs.contains("Peace") {
            profile.socialPreference = "introverted"
        }
        
        // Determine emotional sensitivity
        if concerns.contains("Anxiety") || concerns.contains("Stress") {
            profile.emotionalSensitivity = "high"
        } else if concerns.contains("Motivation") || concerns.contains("Energy") {
            profile.emotionalSensitivity = "moderate"
        }
        
        // Determine goal orientation
        let mainGoals = answers["main_goal"] as? [String] ?? []
        if mainGoals.contains("Fitness") || mainGoals.contains("Health") {
            profile.goalOrientation = "health-focused"
        } else if mainGoals.contains("Mental") || mainGoals.contains("Emotional") {
            profile.goalOrientation = "wellness-focused"
        }
        
        profile.preferredLanguage = "English"
        profile.culturalContext = answers["country"] as? String ?? "Global"
        
        return profile
    }
    
    /// Update recommendation tone based on user profile
    private func updateRecommendationTone() {
        if energyLevel.lowercased().contains("low") {
            recommendationTone = "gentle"
        } else if stressLevel.lowercased().contains("high") {
            recommendationTone = "calming"
        } else if motivationType.lowercased().contains("extrinsic") {
            recommendationTone = "motivating"
        } else {
            recommendationTone = "supportive"
        }
        
        // Determine content complexity
        if userAge > 50 || learningStyle.lowercased().contains("simple") {
            contentComplexity = "simple"
        } else if userAge < 25 || learningStyle.lowercased().contains("advanced") {
            contentComplexity = "advanced"
        } else {
            contentComplexity = "moderate"
        }
    }
    
    /// Get a personalized greeting
    func getPersonalizedGreeting() -> String {
        let timeOfDay = getTimeOfDay()
        let greeting = "Good \(timeOfDay), \(userName.isEmpty ? "friend" : userName)"
        
        // Add contextual element
        if stressLevel.lowercased().contains("high") {
            return "\(greeting). I'm here to help you find some calm today."
        } else if energyLevel.lowercased().contains("low") {
            return "\(greeting). Let's take things easy today."
        } else {
            return "\(greeting). Ready to make today great?"
        }
    }
    
    /// Get time of day
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        default:
            return "evening"
        }
    }
    
    /// Build a comprehensive context string for AI prompts
    func buildAIContextString() -> String {
        var context = """
        USER PROFILE:
        - Name: \(userName.isEmpty ? "Friend" : userName)
        - Age: \(userAge > 0 ? "\(userAge) years old" : "Not specified")
        - Gender: \(gender.isEmpty ? "Not specified" : gender)
        
        PRIMARY GOALS:
        \(formatList(primaryGoals))
        
        GREATEST NEEDS:
        \(formatList(greatestNeeds))
        
        CURRENT FOCUS: \(currentFocus)
        
        HEALTH & WELLNESS STATUS:
        - Energy Level: \(energyLevel)
        - Sleep Quality: \(sleepQuality)
        - Stress Level: \(stressLevel)
        - Fitness Level: \(fitnessLevel)
        
        """
        
        // Add dietary information
        if !dietaryPreferences.isEmpty {
            context += "DIETARY PREFERENCES:\n\(formatList(dietaryPreferences))\n\n"
        }
        
        if !allergies.isEmpty {
            context += "ALLERGIES:\n\(formatList(allergies))\n\n"
        }
        
        // Add mental health context
        if !mentalHealthConcerns.isEmpty {
            context += "MENTAL HEALTH CONCERNS:\n\(formatList(mentalHealthConcerns))\n\n"
        }
        
        if !copingStrategies.isEmpty {
            context += "PREFERRED COPING STRATEGIES:\n\(formatList(copingStrategies))\n\n"
        }
        
        // Add cycle information if applicable
        if gender.lowercased() == "female" {
            context += "CYCLE INFORMATION:\n- Current Phase: \(cyclePhase)\n- Cycle Length: \(cycleLength) days\n\n"
        }
        
        // Add lifestyle context
        context += """
        LIFESTYLE:
        - Work Style: \(workStyle)
        - Activity Preference: \(activityPreference)
        - Time Available: \(timeAvailable)
        - Location: \(country)
        
        COMMUNICATION PREFERENCES:
        - Tone: \(communicationStyle)
        - Learning Style: \(learningStyle)
        - Motivation Type: \(motivationType)
        
        PERSONALITY INSIGHTS:
        - Social Preference: \(personalityProfile.socialPreference)
        - Emotional Sensitivity: \(personalityProfile.emotionalSensitivity)
        - Goal Orientation: \(personalityProfile.goalOrientation)
        
        INSTRUCTIONS:
        1. Use the user's name (\(userName.isEmpty ? "Friend" : userName)) naturally in responses
        2. Reference their specific goals and needs when providing recommendations
        3. Adapt your tone to be \(recommendationTone)
        4. Consider their energy level (\(energyLevel)) when suggesting activities
        5. Be mindful of their stress level (\(stressLevel)) and provide appropriate support
        6. Personalize all recommendations to their specific situation and preferences
        7. Avoid generic advice - everything should feel tailored to them
        """
        
        return context
    }
    
    /// Format a list for readable output
    private func formatList(_ items: [String]) -> String {
        guard !items.isEmpty else { return "Not specified" }
        return items.map { "- \($0)" }.joined(separator: "\n")
    }
}

// MARK: - Personality Profile
struct PersonalityProfile: Codable {
    var socialPreference: String = "balanced"
    var emotionalSensitivity: String = "moderate"
    var goalOrientation: String = "balanced"
    var preferredLanguage: String = "English"
    var culturalContext: String = "Global"
}

// MARK: - Helper Extension for Array contains
extension Array where Element: StringProtocol {
    func contains(anyOf items: [String]) -> Bool {
        for item in items {
            if self.contains { $0.localizedCaseInsensitiveContains(item) } {
                return true
            }
        }
        return false
    }
}
