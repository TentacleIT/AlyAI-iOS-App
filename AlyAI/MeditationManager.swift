import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
class MeditationManager: ObservableObject {
    static let shared = MeditationManager()
    
    @Published var progress: MeditationProgress = MeditationProgress()
    @Published var dailyMeditation: DailyMeditation?
    @Published var meditationLibrary: [MeditationLibraryCategory] = []
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    private let openAIService = OpenAIService.shared
    
    private init() {
        loadProgress()
        loadDailyMeditation()
        loadMeditationLibrary()
    }
    
    // MARK: - Load Data
    
    func loadProgress() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                let doc = try await db.collection("users").document(uid)
                    .collection("meditation").document("progress").getDocument()
                
                if doc.exists {
                    self.progress = try doc.data(as: MeditationProgress.self)
                    print("✅ Meditation progress loaded")
                } else {
                    print("ℹ️ No meditation progress found, starting fresh")
                }
            } catch {
                print("❌ Error loading meditation progress: \(error)")
            }
        }
    }
    
    func loadDailyMeditation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        Task {
            let today = getTodayString()
            
            do {
                let doc = try await db.collection("users").document(uid)
                    .collection("meditation").document("daily_\(today)").getDocument()
                
                if doc.exists {
                    self.dailyMeditation = try doc.data(as: DailyMeditation.self)
                    print("✅ Daily meditation loaded")
                } else {
                    // Generate new daily meditation
                    await generateDailyMeditation()
                }
            } catch {
                print("❌ Error loading daily meditation: \(error)")
                await generateDailyMeditation()
            }
        }
    }
    
    func loadMeditationLibrary() {
        // Load predefined meditation library
        meditationLibrary = createMeditationLibrary()
    }
    
    // MARK: - Save Data
    
    func saveProgress() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let data = try Firestore.Encoder().encode(progress)
            try await db.collection("users").document(uid)
                .collection("meditation").document("progress").setData(data, merge: true)
            print("✅ Meditation progress saved")
        } catch {
            print("❌ Error saving meditation progress: \(error)")
        }
    }
    
    func saveDailyMeditation(_ daily: DailyMeditation) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let data = try Firestore.Encoder().encode(daily)
            try await db.collection("users").document(uid)
                .collection("meditation").document("daily_\(daily.date)").setData(data)
            print("✅ Daily meditation saved")
        } catch {
            print("❌ Error saving daily meditation: \(error)")
        }
    }
    
    // MARK: - Generate Daily Meditation
    
    func generateDailyMeditation() async {
        isLoading = true
        defer { isLoading = false }
        
        // Get user context for personalization
        let context = PersonalizationContext.shared
        let profile = UserProfileManager.shared.currentUserProfile
        
        // Determine best category based on user's needs
        let category = determineBestCategory(for: context)
        
        // Get a video from that category
        guard let video = getVideoForCategory(category) else {
            print("❌ No video found for category: \(category)")
            return
        }
        
        // Generate personalized message using AI
        let message = await generatePersonalizedMessage(for: context, category: category)
        
        // Create daily meditation
        let daily = DailyMeditation(
            video: video,
            personalizedMessage: message,
            recommendedTime: determineRecommendedTime(for: category)
        )
        
        self.dailyMeditation = daily
        await saveDailyMeditation(daily)
    }
    
    private func determineBestCategory(for context: PersonalizationContext) -> MeditationCategory {
        // Analyze user's greatest needs and current focus
        let needs = context.greatestNeeds.map { $0.lowercased() }
        let focus = context.currentFocus.lowercased()
        let stressLevel = Int(context.stressLevel) ?? 0
        let sleepQuality = Int(context.sleepQuality) ?? 0
        let energyLevel = Int(context.energyLevel) ?? 0
        
        // Priority logic
        if stressLevel >= 7 || needs.contains("stress") || focus.contains("stress") {
            return .stressManagement
        } else if sleepQuality <= 3 || needs.contains("sleep") || focus.contains("sleep") {
            return .sleepBetter
        } else if needs.contains("anxiety") || focus.contains("anxiety") {
            return .anxietyRelief
        } else if needs.contains("focus") || focus.contains("focus") || focus.contains("productivity") {
            return .focusClarity
        } else if energyLevel <= 3 {
            return .energyBoost
        } else {
            return .selfCompassion
        }
    }
    
    private func getVideoForCategory(_ category: MeditationCategory) -> MeditationVideo? {
        // Find videos in the library for this category
        let categoryVideos = meditationLibrary.first { $0.category == category }?.videos ?? []
        
        // Return a random video from the category, or create a default one
        if let video = categoryVideos.randomElement() {
            return video
        }
        
        // Fallback: create a default video
        return createDefaultVideo(for: category)
    }
    
    private func createDefaultVideo(for category: MeditationCategory) -> MeditationVideo {
        let titles: [MeditationCategory: String] = [
            .anxietyRelief: "Morning Calm - 10 min",
            .sleepBetter: "Deep Sleep Meditation - 15 min",
            .stressManagement: "Stress Relief - 12 min",
            .focusClarity: "Focus & Clarity - 10 min",
            .selfCompassion: "Self-Love Practice - 15 min",
            .energyBoost: "Energizing Meditation - 8 min"
        ]
        
        let descriptions: [MeditationCategory: String] = [
            .anxietyRelief: "Start your day with focus and clarity.",
            .sleepBetter: "Drift into peaceful, restful sleep.",
            .stressManagement: "Release tension and find inner peace.",
            .focusClarity: "Sharpen your mind and enhance concentration.",
            .selfCompassion: "Cultivate kindness and compassion within.",
            .energyBoost: "Revitalize your body and awaken your spirit."
        ]
        
        return MeditationVideo(
            title: titles[category] ?? "Daily Meditation",
            duration: 10,
            description: descriptions[category] ?? "A guided meditation for your wellbeing.",
            category: category,
            videoURL: nil, // Will be populated with actual video URLs
            thumbnailURL: nil,
            isDaily: true,
            tags: [category.rawValue]
        )
    }
    
    private func generatePersonalizedMessage(for context: PersonalizationContext, category: MeditationCategory) async -> String {
        let userName = context.userName.isEmpty ? "there" : context.userName
        let timeOfDay = getTimeOfDay()
        
        // Simple personalized messages based on category
        let messages: [MeditationCategory: String] = [
            .anxietyRelief: "Good \(timeOfDay), \(userName). Take a moment to breathe and release any tension you're holding.",
            .sleepBetter: "Good \(timeOfDay), \(userName). Prepare your mind and body for deep, restful sleep.",
            .stressManagement: "Good \(timeOfDay), \(userName). Let's find balance and calm in this moment.",
            .focusClarity: "Good \(timeOfDay), \(userName). Sharpen your focus and bring clarity to your day.",
            .selfCompassion: "Good \(timeOfDay), \(userName). You deserve kindness and compassion, starting with yourself.",
            .energyBoost: "Good \(timeOfDay), \(userName). Let's awaken your energy and vitality."
        ]
        
        return messages[category] ?? "Good \(timeOfDay), \(userName). Take this time for yourself."
    }
    
    private func determineRecommendedTime(for category: MeditationCategory) -> String {
        switch category {
        case .sleepBetter:
            return "Evening"
        case .energyBoost:
            return "Morning"
        case .focusClarity:
            return "Morning"
        default:
            return "Anytime"
        }
    }
    
    // MARK: - Record Session
    
    func recordSession(video: MeditationVideo) async {
        progress.recordSession(
            sessionId: video.id,
            duration: video.duration,
            category: video.category
        )
        await saveProgress()
        print("✅ Meditation session recorded")
    }
    
    // MARK: - Meditation Library
    
    private func createMeditationLibrary() -> [MeditationLibraryCategory] {
        var library: [MeditationLibraryCategory] = []
        
        // Anxiety Relief
        let anxietyVideos = [
            MeditationVideo(
                title: "Morning Calm - 10 min",
                duration: 10,
                description: "Start your day with focus and clarity.",
                category: .anxietyRelief,
                tags: ["morning", "calm", "anxiety"]
            ),
            MeditationVideo(
                title: "Anxiety Release - 15 min",
                duration: 15,
                description: "Release tension and find peace.",
                category: .anxietyRelief,
                tags: ["anxiety", "release", "peace"]
            ),
            MeditationVideo(
                title: "Quick Calm - 5 min",
                duration: 5,
                description: "Fast relief when you need it most.",
                category: .anxietyRelief,
                tags: ["quick", "anxiety", "relief"]
            )
        ]
        library.append(MeditationLibraryCategory(category: .anxietyRelief, videos: anxietyVideos))
        
        // Sleep Better
        let sleepVideos = [
            MeditationVideo(
                title: "Deep Sleep - 20 min",
                duration: 20,
                description: "Drift into restful slumber.",
                category: .sleepBetter,
                tags: ["sleep", "deep", "rest"]
            ),
            MeditationVideo(
                title: "Bedtime Relaxation - 15 min",
                duration: 15,
                description: "Prepare your mind for sleep.",
                category: .sleepBetter,
                tags: ["sleep", "bedtime", "relaxation"]
            ),
            MeditationVideo(
                title: "Sleep Soundly - 30 min",
                duration: 30,
                description: "Extended meditation for deep rest.",
                category: .sleepBetter,
                tags: ["sleep", "extended", "deep"]
            )
        ]
        library.append(MeditationLibraryCategory(category: .sleepBetter, videos: sleepVideos))
        
        // Stress Management
        let stressVideos = [
            MeditationVideo(
                title: "Stress Relief - 12 min",
                duration: 12,
                description: "Find balance in daily life.",
                category: .stressManagement,
                tags: ["stress", "relief", "balance"]
            ),
            MeditationVideo(
                title: "Tension Release - 10 min",
                duration: 10,
                description: "Let go of physical and mental tension.",
                category: .stressManagement,
                tags: ["stress", "tension", "release"]
            ),
            MeditationVideo(
                title: "Calm Mind - 15 min",
                duration: 15,
                description: "Quiet your racing thoughts.",
                category: .stressManagement,
                tags: ["stress", "calm", "mind"]
            )
        ]
        library.append(MeditationLibraryCategory(category: .stressManagement, videos: stressVideos))
        
        // Focus & Clarity
        let focusVideos = [
            MeditationVideo(
                title: "Mental Clarity - 10 min",
                duration: 10,
                description: "Sharpen your mental clarity.",
                category: .focusClarity,
                tags: ["focus", "clarity", "concentration"]
            ),
            MeditationVideo(
                title: "Productivity Boost - 8 min",
                duration: 8,
                description: "Enhance your focus and productivity.",
                category: .focusClarity,
                tags: ["focus", "productivity", "work"]
            )
        ]
        library.append(MeditationLibraryCategory(category: .focusClarity, videos: focusVideos))
        
        // Self-Compassion
        let compassionVideos = [
            MeditationVideo(
                title: "Loving-Kindness - 15 min",
                duration: 15,
                description: "Cultivate kindness within.",
                category: .selfCompassion,
                tags: ["compassion", "kindness", "love"]
            ),
            MeditationVideo(
                title: "Self-Love Practice - 12 min",
                duration: 12,
                description: "Embrace yourself with compassion.",
                category: .selfCompassion,
                tags: ["self-love", "compassion", "acceptance"]
            )
        ]
        library.append(MeditationLibraryCategory(category: .selfCompassion, videos: compassionVideos))
        
        // Energy Boost
        let energyVideos = [
            MeditationVideo(
                title: "Morning Energy - 8 min",
                duration: 8,
                description: "Revitalize your mind and body.",
                category: .energyBoost,
                tags: ["energy", "morning", "vitality"]
            ),
            MeditationVideo(
                title: "Afternoon Refresh - 10 min",
                duration: 10,
                description: "Beat the afternoon slump.",
                category: .energyBoost,
                tags: ["energy", "afternoon", "refresh"]
            )
        ]
        library.append(MeditationLibraryCategory(category: .energyBoost, videos: energyVideos))
        
        return library
    }
    
    // MARK: - Helpers
    
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
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
}
