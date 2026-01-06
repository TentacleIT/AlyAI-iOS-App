import Foundation
// import FirebaseFirestoreSwift // Module not available, removing @DocumentID
import FirebaseFirestore

// MARK: - Support Plan Item

struct SupportPlanItem: Identifiable, Codable {
    var id = UUID()
    let title: String
    let icon: String
    var description: String?
    var relatedNeeds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title, icon, description, relatedNeeds = "related_needs"
    }
    
    // Custom decoding to handle optional fields and auto-generation of ID
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.icon = try container.decode(String.self, forKey: .icon)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.relatedNeeds = try container.decodeIfPresent([String].self, forKey: .relatedNeeds)
    }
    
    // Manual init
    init(title: String, icon: String, description: String? = nil, relatedNeeds: [String]? = nil) {
        self.title = title
        self.icon = icon
        self.description = description
        self.relatedNeeds = relatedNeeds
    }
    
    // Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(icon, forKey: .icon)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(relatedNeeds, forKey: .relatedNeeds)
    }
}

// MARK: - Greatest Need

struct GreatestNeed: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    var isSelected: Bool = false
    
    init(id: UUID = UUID(), title: String, description: String, icon: String, isSelected: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isSelected = isSelected
    }
    
    // Hashable for Set usage
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GreatestNeed, rhs: GreatestNeed) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Recommended Action

struct RecommendedAction: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let relatedNeed: String
    let suggestedFrequency: String
    let priority: String // high, medium, low
    
    enum CodingKeys: String, CodingKey {
        case title, description, relatedNeed = "related_need", suggestedFrequency = "suggested_frequency", priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.relatedNeed = try container.decode(String.self, forKey: .relatedNeed)
        self.suggestedFrequency = try container.decode(String.self, forKey: .suggestedFrequency)
        self.priority = try container.decode(String.self, forKey: .priority)
    }
    
    init(title: String, description: String, relatedNeed: String, suggestedFrequency: String, priority: String) {
        self.title = title
        self.description = description
        self.relatedNeed = relatedNeed
        self.suggestedFrequency = suggestedFrequency
        self.priority = priority
    }
}

// MARK: - Daily Meal Plan

struct MealDetail: Codable {
    let title: String
    let description: String
    let whyItHelps: String
    let imagePrompt: String
    let howToPrepare: String
    var imageUrl: String? // Optional: filled after image generation
}

struct DailyMealPlanMeals: Codable {
    var breakfast: MealDetail
    var lunch: MealDetail
    var dinner: MealDetail
}

struct DailyMealPlan: Codable {
    let date: String
    let progressNote: String?
    var meals: DailyMealPlanMeals
    
    // Extended Metadata
    var caloriesEstimate: Int?
    var countryUsed: String?
    var cyclePhase: String?
    var symptomsConsidered: [String]?
    var moodContext: String?
}

struct NutritionPreferences: Codable {
    var country: String
    var region: String?
    var dietType: String
    var allergies: [String]
    var excludedFoods: [String]
    var budgetLevel: String = "Medium"
    var lastUpdated: Date = Date()
    
    init(country: String = "Global", dietType: String = "Balanced", allergies: [String] = [], excludedFoods: [String] = []) {
        self.country = country
        self.dietType = dietType
        self.allergies = allergies
        self.excludedFoods = excludedFoods
    }
}

// MARK: - Notification Models

struct NotificationPreferences: Codable {
    var pushEnabled: Bool = true
    var inAppEnabled: Bool = true
    var emailEnabled: Bool = false
    var moduleOptIn: [String] = ["Health", "Mood", "AI", "Cycle", "Subscription", "System"]
    var lastUpdated: Date = Date()
    // Quiet hours would require more complex implementation, simplified for now
}

struct SentNotification: Codable, Identifiable {
    var id: String?
    var type: String
    var content: String
    var actionLink: String?
    var urgency: String
    var readStatus: Bool = false
    var context: [String]
    var createdAt: Date = Date()
}

// MARK: - Appointment Models

struct Appointment: Codable, Identifiable, Hashable {
    var id: String?
    var specialistType: String
    var appointmentType: String // "Virtual" or "In-person"
    var scheduledDateTime: Date
    var timezone: String
    var status: String // "Scheduled", "Completed", "Cancelled"
    var notes: String?
    var specialistMetadata: SpecialistMetadata?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var source: String = "quick_actions"
    
    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SpecialistMetadata: Codable {
    var name: String?
    var specialty: String
    var providerId: String?
}

// MARK: - Device Model for Push Notifications

struct Device: Codable {
    var platform: String = "ios"
    var fcmToken: String
    var notificationsEnabled: Bool = true
    var appVersion: String
    var lastSeen: Date = Date()
    var createdAt: Date = Date()
}

// MARK: - Assessment Result

struct AssessmentResult: Codable {
    let title: String
    let summary: String
    let planExplanation: String
    let focusArea: String
    
    let dailyCheckins: Int
    let sleepHours: Double
    let mindfulnessMinutes: Int
    let emotionalResilience: Int // 0-100 score
    let healthScore: Int
    // New structured data
    let keyInsights: [String]
    let identifiedNeeds: [String]
    let recommendedActions: [RecommendedAction]
    
    enum CodingKeys: String, CodingKey {
        case title = "message" // Mapping message from OpenAI to title for now, or we can use a separate title if provided
        case summary = "assessment_summary"
        case planExplanation
        case focusArea = "focus_area" // Assuming this might come back or we default it
        case dailyCheckins
        case sleepHours
        case mindfulnessMinutes
        case emotionalResilience
        case healthScore
        case keyInsights = "key_insights"
        case identifiedNeeds = "identified_needs"
        case recommendedActions = "recommended_actions"
    }
    
    // Helper to allow manual creation if needed (e.g. for previews or partial updates)
    init(title: String, summary: String, planExplanation: String, focusArea: String, dailyCheckins: Int, sleepHours: Double, mindfulnessMinutes: Int, emotionalResilience: Int, healthScore: Int, keyInsights: [String], identifiedNeeds: [String], recommendedActions: [RecommendedAction]) {
        self.title = title
        self.summary = summary
        self.planExplanation = planExplanation
        self.focusArea = focusArea
        self.dailyCheckins = dailyCheckins
        self.sleepHours = sleepHours
        self.mindfulnessMinutes = mindfulnessMinutes
        self.emotionalResilience = emotionalResilience
        self.healthScore = healthScore
        self.keyInsights = keyInsights
        self.identifiedNeeds = identifiedNeeds
        self.recommendedActions = recommendedActions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Your Wellness Plan"
        self.summary = try container.decodeIfPresent(String.self, forKey: .summary) ?? ""
        self.planExplanation = try container.decodeIfPresent(String.self, forKey: .planExplanation) ?? ""
        self.focusArea = try container.decodeIfPresent(String.self, forKey: .focusArea) ?? "General Wellness"
        self.dailyCheckins = try container.decodeIfPresent(Int.self, forKey: .dailyCheckins) ?? 1
        self.sleepHours = try container.decodeIfPresent(Double.self, forKey: .sleepHours) ?? 7.0
        self.mindfulnessMinutes = try container.decodeIfPresent(Int.self, forKey: .mindfulnessMinutes) ?? 10
        self.emotionalResilience = try container.decodeIfPresent(Int.self, forKey: .emotionalResilience) ?? 50
        self.healthScore = try container.decodeIfPresent(Int.self, forKey: .healthScore) ?? 5
        self.keyInsights = try container.decodeIfPresent([String].self, forKey: .keyInsights) ?? []
        self.identifiedNeeds = try container.decodeIfPresent([String].self, forKey: .identifiedNeeds) ?? []
        self.recommendedActions = try container.decodeIfPresent([RecommendedAction].self, forKey: .recommendedActions) ?? []
    }
}

// MARK: - Therapist Voice Models

enum TherapistVoiceOption: String, CaseIterable, Identifiable, Codable {
    case sarah = "sarah_female"
    case daniel = "daniel_male"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .sarah: return "Sarah"
        case .daniel: return "Daniel"
        }
    }
    
    var gender: String {
        switch self {
        case .sarah: return "Female"
        case .daniel: return "Male"
        }
    }
    
    var tone: String {
        switch self {
        case .sarah: return "Calm & Reassuring"
        case .daniel: return "Deep & Grounded"
        }
    }
    
    var providerVoiceKey: String {
        switch self {
        case .sarah: return "shimmer"
        case .daniel: return "onyx"
        }
    }
    
    var description: String {
        switch self {
        case .sarah: return "A warm, empathetic voice that offers comfort and understanding."
        case .daniel: return "A steady, supportive voice that helps you feel grounded and safe."
        }
    }
}

struct TherapistVoicePreference: Codable {
    var voiceId: String
    var gender: String
    var tone: String
    var providerVoiceKey: String
    var lastUpdated: Date
    
    static var `default`: TherapistVoicePreference {
        let voice = TherapistVoiceOption.sarah
        return TherapistVoicePreference(
            voiceId: voice.id,
            gender: voice.gender.lowercased(),
            tone: voice.tone,
            providerVoiceKey: voice.providerVoiceKey,
            lastUpdated: Date()
        )
    }
}
