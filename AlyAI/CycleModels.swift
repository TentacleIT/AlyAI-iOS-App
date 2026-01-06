import Foundation
import FirebaseFirestore

// MARK: - Enums
enum CyclePhase: String, Codable, CaseIterable {
    case menstrual = "Menstrual"
    case follicular = "Follicular"
    case ovulation = "Ovulation"
    case luteal = "Luteal"
    case unknown = "Tracking"
    
    var description: String {
        switch self {
        case .menstrual: return "Rest & Reflect"
        case .follicular: return "Energy Rising"
        case .ovulation: return "Peak Energy"
        case .luteal: return "Winding Down"
        case .unknown: return "Getting to know your cycle"
        }
    }
}

enum PeriodFlow: String, Codable, CaseIterable {
    case none, light, medium, heavy
}

// MARK: - Core Cycle Metadata
struct CycleMetadata: Codable {
    var lastPeriodDate: Date?
    var cycleLength: Int = 28
    var lutealLength: Int = 14
    var ovulationEstimate: Date?
    var migrationCompleted: Bool = false
}

// MARK: - Cycle Log (Daily Entry)
struct CycleLog: Codable, Identifiable {
    @DocumentID var id: String? // Date String yyyy-MM-dd
    var date: Date
    var cyclePhase: CyclePhase
    var flowLevel: PeriodFlow
    var symptoms: CycleSymptoms
    var mood: CycleMood
    var energyLevel: Int // 1-10
    var sleepQuality: Int // 1-5
    var bodyTemperature: Double?
    
    // Default init for new logs
    init(date: Date, phase: CyclePhase) {
        self.date = date
        self.cyclePhase = phase
        self.flowLevel = .none
        self.symptoms = CycleSymptoms()
        self.mood = CycleMood()
        self.energyLevel = 5
        self.sleepQuality = 3
    }
}

// MARK: - Symptoms Structure
struct CycleSymptoms: Codable {
    var cramps: SymptomEntry?
    var bloating: SymptomEntry?
    var breastTenderness: SymptomEntry?
    var headache: SymptomEntry?
    var backPain: SymptomEntry?
    var jointPain: SymptomEntry?
    var nausea: SymptomEntry?
    var cravings: SymptomEntry?
    var discharge: DischargeEntry?
    var appetiteChange: SymptomEntry?
    
    init() {}
}

struct SymptomEntry: Codable, Hashable {
    var isPresent: Bool
    var severity: SymptomSeverity // none, light, medium, heavy
    var notes: String?
    
    init(isPresent: Bool = false, severity: SymptomSeverity = .none, notes: String? = nil) {
        self.isPresent = isPresent
        self.severity = severity
        self.notes = notes
    }
}

enum SymptomSeverity: String, Codable, CaseIterable {
    case none = "None"
    case light = "Light"
    case medium = "Medium"
    case heavy = "Heavy"
}

struct DischargeEntry: Codable, Hashable {
    var type: DischargeType
    var notes: String?
    
    init(type: DischargeType = .none, notes: String? = nil) {
        self.type = type
        self.notes = notes
    }
}

enum DischargeType: String, Codable, CaseIterable {
    case none = "None"
    case dry = "Dry"
    case sticky = "Sticky"
    case creamy = "Creamy"
    case eggWhite = "Egg White"
    case watery = "Watery"
}

// MARK: - Mood Structure
struct CycleMood: Codable {
    var state: MoodState?
    var intensity: Int = 5 // 1-10
    var notes: String?
    
    init(state: MoodState? = nil, intensity: Int = 5, notes: String? = nil) {
        self.state = state
        self.intensity = intensity
        self.notes = notes
    }
}

enum MoodState: String, Codable, CaseIterable {
    case happy = "Happy"
    case anxious = "Anxious"
    case irritable = "Irritable"
    case low = "Low"
    case calm = "Calm"
    case energetic = "Energetic"
    case sensitive = "Sensitive"
}

// MARK: - Insights Structure
struct CycleInsight: Codable, Identifiable {
    @DocumentID var id: String? // Date String yyyy-MM-dd
    var date: Date
    var explanation: String
    var whatToExpect: String
    var copingTips: [String]
    var confidenceScore: Int // 0-100
}
