import Foundation
import FirebaseFirestore

/// Codable model for persisting PersonalizationContext to Firestore
struct PersonalizationData: Codable {
    // MARK: - User Demographics
    var userName: String
    var userAge: Int
    var gender: String
    
    // MARK: - Primary Goals & Needs
    var primaryGoals: [String]
    var greatestNeeds: [String]
    var currentFocus: String
    
    // MARK: - Health & Wellness
    var energyLevel: String
    var sleepQuality: String
    var stressLevel: String
    var fitnessLevel: String
    var dietaryPreferences: [String]
    var allergies: [String]
    
    // MARK: - Cycle Information
    var cyclePhase: String
    var cycleLength: Int
    
    // MARK: - Mental Health
    var mentalHealthConcerns: [String]
    var copingStrategies: [String]
    var supportSystem: String
    
    // MARK: - Lifestyle
    var workStyle: String
    var activityPreference: String
    var timeAvailable: String
    var country: String
    
    // MARK: - Preferences
    var communicationStyle: String
    var learningStyle: String
    var motivationType: String
    
    // MARK: - Derived Personalization Signals
    var personalityProfile: PersonalityProfile
    var recommendationTone: String
    var contentComplexity: String
    
    // MARK: - Metadata
    var lastUpdated: Date
    
    init() {
        self.userName = ""
        self.userAge = 0
        self.gender = ""
        self.primaryGoals = []
        self.greatestNeeds = []
        self.currentFocus = ""
        self.energyLevel = ""
        self.sleepQuality = ""
        self.stressLevel = ""
        self.fitnessLevel = ""
        self.dietaryPreferences = []
        self.allergies = []
        self.cyclePhase = ""
        self.cycleLength = 28
        self.mentalHealthConcerns = []
        self.copingStrategies = []
        self.supportSystem = ""
        self.workStyle = ""
        self.activityPreference = ""
        self.timeAvailable = ""
        self.country = ""
        self.communicationStyle = "warm"
        self.learningStyle = "visual"
        self.motivationType = "intrinsic"
        self.personalityProfile = PersonalityProfile()
        self.recommendationTone = "supportive"
        self.contentComplexity = "moderate"
        self.lastUpdated = Date()
    }
    
    init(from context: PersonalizationContext) {
        self.userName = context.userName
        self.userAge = context.userAge
        self.gender = context.gender
        self.primaryGoals = context.primaryGoals
        self.greatestNeeds = context.greatestNeeds
        self.currentFocus = context.currentFocus
        self.energyLevel = context.energyLevel
        self.sleepQuality = context.sleepQuality
        self.stressLevel = context.stressLevel
        self.fitnessLevel = context.fitnessLevel
        self.dietaryPreferences = context.dietaryPreferences
        self.allergies = context.allergies
        self.cyclePhase = context.cyclePhase
        self.cycleLength = context.cycleLength
        self.mentalHealthConcerns = context.mentalHealthConcerns
        self.copingStrategies = context.copingStrategies
        self.supportSystem = context.supportSystem
        self.workStyle = context.workStyle
        self.activityPreference = context.activityPreference
        self.timeAvailable = context.timeAvailable
        self.country = context.country
        self.communicationStyle = context.communicationStyle
        self.learningStyle = context.learningStyle
        self.motivationType = context.motivationType
        self.personalityProfile = context.personalityProfile
        self.recommendationTone = context.recommendationTone
        self.contentComplexity = context.contentComplexity
        self.lastUpdated = Date()
    }
    
    func applyTo(context: PersonalizationContext) {
        context.userName = self.userName
        context.userAge = self.userAge
        context.gender = self.gender
        context.primaryGoals = self.primaryGoals
        context.greatestNeeds = self.greatestNeeds
        context.currentFocus = self.currentFocus
        context.energyLevel = self.energyLevel
        context.sleepQuality = self.sleepQuality
        context.stressLevel = self.stressLevel
        context.fitnessLevel = self.fitnessLevel
        context.dietaryPreferences = self.dietaryPreferences
        context.allergies = self.allergies
        context.cyclePhase = self.cyclePhase
        context.cycleLength = self.cycleLength
        context.mentalHealthConcerns = self.mentalHealthConcerns
        context.copingStrategies = self.copingStrategies
        context.supportSystem = self.supportSystem
        context.workStyle = self.workStyle
        context.activityPreference = self.activityPreference
        context.timeAvailable = self.timeAvailable
        context.country = self.country
        context.communicationStyle = self.communicationStyle
        context.learningStyle = self.learningStyle
        context.motivationType = self.motivationType
        context.personalityProfile = self.personalityProfile
        context.recommendationTone = self.recommendationTone
        context.contentComplexity = self.contentComplexity
    }
}
