import Foundation
import FirebaseFirestore

// MARK: - Meditation Category

enum MeditationCategory: String, Codable, CaseIterable {
    case anxietyRelief = "Anxiety Relief"
    case sleepBetter = "Sleep Better"
    case stressManagement = "Stress Management"
    case focusClarity = "Focus & Clarity"
    case selfCompassion = "Self-Compassion"
    case energyBoost = "Energy Boost"
    
    var icon: String {
        switch self {
        case .anxietyRelief: return "leaf.fill"
        case .sleepBetter: return "moon.stars.fill"
        case .stressManagement: return "figure.mind.and.body"
        case .focusClarity: return "brain.head.profile"
        case .selfCompassion: return "heart.fill"
        case .energyBoost: return "bolt.fill"
        }
    }
    
    var color: String {
        switch self {
        case .anxietyRelief: return "cyan"
        case .sleepBetter: return "indigo"
        case .stressManagement: return "purple"
        case .focusClarity: return "blue"
        case .selfCompassion: return "pink"
        case .energyBoost: return "orange"
        }
    }
    
    var description: String {
        switch self {
        case .anxietyRelief: return "Release tension and find peace."
        case .sleepBetter: return "Drift into restful slumber."
        case .stressManagement: return "Find balance in daily life."
        case .focusClarity: return "Sharpen your mental clarity."
        case .selfCompassion: return "Cultivate kindness within."
        case .energyBoost: return "Revitalize your mind and body."
        }
    }
}

// MARK: - Meditation Video

struct MeditationVideo: Identifiable, Codable {
    let id: String
    let title: String
    let duration: Int // in minutes
    let description: String
    let category: MeditationCategory
    let videoURL: String? // YouTube URL or video file URL
    let thumbnailURL: String?
    let isDaily: Bool // True if this is the daily generated meditation
    let createdAt: Date
    let tags: [String]
    
    init(id: String = UUID().uuidString,
         title: String,
         duration: Int,
         description: String,
         category: MeditationCategory,
         videoURL: String? = nil,
         thumbnailURL: String? = nil,
         isDaily: Bool = false,
         createdAt: Date = Date(),
         tags: [String] = []) {
        self.id = id
        self.title = title
        self.duration = duration
        self.description = description
        self.category = category
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.isDaily = isDaily
        self.createdAt = createdAt
        self.tags = tags
    }
}

// MARK: - Meditation Progress

struct MeditationProgress: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var totalSessions: Int
    var totalMinutes: Int
    var lastMeditationDate: Date?
    var completedSessions: [String] // Array of session IDs
    var categoryProgress: [String: Int] // Category name -> session count
    
    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalSessions = 0
        self.totalMinutes = 0
        self.lastMeditationDate = nil
        self.completedSessions = []
        self.categoryProgress = [:]
    }
    
    mutating func recordSession(sessionId: String, duration: Int, category: MeditationCategory) {
        // Update totals
        totalSessions += 1
        totalMinutes += duration
        completedSessions.append(sessionId)
        
        // Update category progress
        let categoryKey = category.rawValue
        categoryProgress[categoryKey, default: 0] += 1
        
        // Update streak
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = lastMeditationDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDifference = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Same day, no streak change
            } else if daysDifference == 1 {
                // Consecutive day, increment streak
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else {
                // Streak broken, reset to 1
                currentStreak = 1
            }
        } else {
            // First meditation
            currentStreak = 1
            longestStreak = 1
        }
        
        lastMeditationDate = Date()
    }
    
    func getStreakStatus() -> String {
        guard let lastDate = lastMeditationDate else {
            return "Start your journey today!"
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let daysDifference = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
        
        if daysDifference == 0 {
            return "🔥 \(currentStreak) day streak"
        } else if daysDifference == 1 {
            return "Meditate today to continue your \(currentStreak) day streak!"
        } else {
            return "Start a new streak today!"
        }
    }
}

// MARK: - Daily Meditation

struct DailyMeditation: Codable {
    let date: String // yyyy-MM-dd format
    let video: MeditationVideo
    let personalizedMessage: String
    let recommendedTime: String // e.g., "Morning", "Evening"
    
    init(date: Date = Date(),
         video: MeditationVideo,
         personalizedMessage: String,
         recommendedTime: String = "Morning") {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.date = formatter.string(from: date)
        self.video = video
        self.personalizedMessage = personalizedMessage
        self.recommendedTime = recommendedTime
    }
}

// MARK: - Meditation Library Category

struct MeditationLibraryCategory: Identifiable {
    let id = UUID()
    let category: MeditationCategory
    let sessionCount: Int
    let videos: [MeditationVideo]
    
    init(category: MeditationCategory, videos: [MeditationVideo]) {
        self.category = category
        self.videos = videos
        self.sessionCount = videos.count
    }
}
