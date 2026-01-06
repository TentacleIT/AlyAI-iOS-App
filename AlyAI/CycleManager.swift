import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - Legacy Support
private struct LegacyCycleData: Codable {
    var lastPeriodStart: Date?
    var averageCycleLength: Int = 28
    var logs: [String: LegacyDailyCycleLog] = [:]
}

private struct LegacyDailyCycleLog: Codable {
    var mood: String?
    var energy: Int?
    var symptoms: [String]?
    var periodFlow: PeriodFlow?
}

@MainActor
class CycleManager: ObservableObject {
    static let shared = CycleManager()
    
    @Published var metadata: CycleMetadata = CycleMetadata()
    @Published var todayLog: CycleLog?
    @Published var todayInsight: CycleInsight?
    
    // Cache for calendar view
    @Published var monthLogs: [Date: CycleLog] = [:]
    
    private var db = Firestore.firestore()
    private var metadataListener: ListenerRegistration?
    private var logListener: ListenerRegistration?
    private var logsCollectionListener: ListenerRegistration?
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.subscribe(for: user.uid)
            } else {
                self?.unsubscribe()
            }
        }
    }
    
    private func unsubscribe() {
        metadataListener?.remove()
        logListener?.remove()
        logsCollectionListener?.remove()
        
        metadata = CycleMetadata()
        todayLog = nil
        todayInsight = nil
        monthLogs = [:]
    }

    private func subscribe(for uid: String) {
        unsubscribe()
        
        // 1. Subscribe to Metadata
        let metaRef = db.collection("users").document(uid).collection("cycleData").document("data")
        metadataListener = metaRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                if let data = try? document.data(as: CycleMetadata.self) {
                    self.metadata = data
                    
                    // Check for migration needed
                    if !data.migrationCompleted {
                        self.checkAndMigrateLegacyData(uid: uid)
                    }
                } else {
                    // Might be legacy format or corrupted
                    self.checkAndMigrateLegacyData(uid: uid)
                }
            } else {
                // No data exists, clean slate
                self.metadata = CycleMetadata()
            }
        }
        
        // 2. Subscribe to Today's Log
        let today = Date()
        let todayStr = formatDate(today)
        let logRef = db.collection("users").document(uid).collection("cycleLogs").document(todayStr)
        
        logListener = logRef.addSnapshotListener { [weak self] (document, error) in
            if let document = document, document.exists, let log = try? document.data(as: CycleLog.self) {
                self?.todayLog = log
                self?.generateDailyInsight(log: log)
            } else {
                // Initialize empty log for today in memory (not saved yet)
                guard let self = self else { return }
                self.todayLog = CycleLog(date: today, phase: self.currentPhase)
            }
        }
        
        // 3. Subscribe to recent logs (e.g. last 30 days) for calendar/history
        // For simplicity, just grabbing last 40 days
        let logsRef = db.collection("users").document(uid).collection("cycleLogs")
            .whereField("date", isGreaterThan: Calendar.current.date(byAdding: .day, value: -40, to: Date())!)
        
        logsCollectionListener = logsRef.addSnapshotListener { [weak self] (snapshot, error) in
            guard let self = self, let docs = snapshot?.documents else { return }
            var logs: [Date: CycleLog] = [:]
            for doc in docs {
                if let log = try? doc.data(as: CycleLog.self) {
                    let startOfDay = Calendar.current.startOfDay(for: log.date)
                    logs[startOfDay] = log
                }
            }
            self.monthLogs = logs
        }
    }
    
    private func checkAndMigrateLegacyData(uid: String) {
        let docRef = db.collection("users").document(uid).collection("cycleData").document("data")
        
        docRef.getDocument { [weak self] (document, error) in
            guard let document = document, document.exists,
                  let legacy = try? document.data(as: LegacyCycleData.self) else { return }
            
            print("🔄 [CycleManager] Migrating legacy cycle data...")
            self?.performMigration(legacy: legacy, uid: uid)
        }
    }
    
    private func performMigration(legacy: LegacyCycleData, uid: String) {
        let batch = db.batch()
        
        // 1. Convert Metadata
        var newMeta = CycleMetadata()
        newMeta.lastPeriodDate = legacy.lastPeriodStart
        newMeta.cycleLength = legacy.averageCycleLength
        newMeta.migrationCompleted = true
        
        let metaRef = db.collection("users").document(uid).collection("cycleData").document("data")
        try? batch.setData(from: newMeta, forDocument: metaRef)
        
        // 2. Convert Logs
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate] // Ensure yyyy-MM-dd format matching keys?
        // Actually legacy keys were probably ISO8601 full date string or just date.
        // Let's assume keys are date strings.
        
        for (dateStr, oldLog) in legacy.logs {
            // Parse date
            guard let date = self.parseDate(dateStr) else { continue }
            let logId = self.formatDate(date)
            let logRef = db.collection("users").document(uid).collection("cycleLogs").document(logId)
            
            var newLog = CycleLog(date: date, phase: .unknown) // Phase calculation might be complex here, keeping unknown or calculating
            newLog.flowLevel = oldLog.periodFlow ?? .none
            newLog.energyLevel = oldLog.energy ?? 5
            
            // Map symptoms
            if let oldSymptoms = oldLog.symptoms {
                for sym in oldSymptoms {
                    switch sym {
                    case "Cramps": newLog.symptoms.cramps = SymptomEntry(isPresent: true, severity: .medium)
                    case "Fatigue": newLog.symptoms.backPain = SymptomEntry(isPresent: true) // Mapping approximation
                    case "Headache": newLog.symptoms.headache = SymptomEntry(isPresent: true)
                    case "Acne": newLog.symptoms.appetiteChange = SymptomEntry(isPresent: true, notes: "Acne") // Mapping to notes or closest
                    case "Nausea": newLog.symptoms.nausea = SymptomEntry(isPresent: true)
                    case "Cravings": newLog.symptoms.cravings = SymptomEntry(isPresent: true)
                    default: break
                    }
                }
            }
            
            // Map Mood
            if let m = oldLog.mood {
                // Map string to enum if possible
                if let state = MoodState(rawValue: m) {
                    newLog.mood.state = state
                } else {
                    newLog.mood.notes = m
                }
            }
            
            try? batch.setData(from: newLog, forDocument: logRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ [CycleManager] Migration failed: \(error)")
            } else {
                print("✅ [CycleManager] Migration completed successfully.")
            }
        }
    }
    
    // MARK: - CRUD
    
    func saveLog(_ log: CycleLog) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let logId = formatDate(log.date)
        let logRef = db.collection("users").document(uid).collection("cycleLogs").document(logId)
        
        do {
            try logRef.setData(from: log, merge: true)
            // If it's today's log, generate insight
            if Calendar.current.isDateInToday(log.date) {
                generateDailyInsight(log: log)
            }
        } catch {
            print("❌ Error saving cycle log: \(error)")
        }
    }
    
    func updateMetadata(lastPeriod: Date? = nil, length: Int? = nil) {
        if let lastPeriod = lastPeriod {
            metadata.lastPeriodDate = lastPeriod
        }
        if let length = length {
            metadata.cycleLength = length
        }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = db.collection("users").document(uid).collection("cycleData").document("data")
        try? ref.setData(from: metadata, merge: true)
        
        // Predictive notifications are now handled by the centralized NotificationManager.
    }
    
    // MARK: - Logic & Predictions
    
    var currentPhase: CyclePhase {
        guard let start = metadata.lastPeriodDate else { return .unknown }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        let dayInCycle = (days % metadata.cycleLength) + 1
        
        if dayInCycle <= 5 { return .menstrual }
        if dayInCycle <= (metadata.cycleLength / 2 - 2) { return .follicular }
        if dayInCycle <= (metadata.cycleLength / 2 + 2) { return .ovulation }
        return .luteal
    }
    
    var currentDayInCycle: Int {
        guard let start = metadata.lastPeriodDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return (days % metadata.cycleLength) + 1
    }
    
    var estimatedNextPeriod: Date? {
        guard let start = metadata.lastPeriodDate else { return nil }
        let currentCycleIndex = (Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0) / metadata.cycleLength
        let nextCycleStartDay = (currentCycleIndex + 1) * metadata.cycleLength
        return Calendar.current.date(byAdding: .day, value: nextCycleStartDay, to: start)
    }
    
    func phase(for date: Date) -> CyclePhase {
        guard let start = metadata.lastPeriodDate else { return .unknown }
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.day], from: start, to: date)
        guard let daysDiff = components.day else { return .unknown }
        
        var dayIndex = daysDiff % metadata.cycleLength
        if dayIndex < 0 {
            dayIndex += metadata.cycleLength
        }
        
        let dayInCycle = dayIndex + 1
        
        if dayInCycle <= 5 { return .menstrual }
        if dayInCycle <= (metadata.cycleLength / 2 - 2) { return .follicular }
        if dayInCycle <= (metadata.cycleLength / 2 + 2) { return .ovulation }
        return .luteal
    }
    
    func getCycleContextForAI() -> String {
        let phase = currentPhase
        let day = currentDayInCycle
        
        var context = """
        User's Cycle Context:
        - Current Phase: \(phase.rawValue) (\(phase.description))
        - Day in Cycle: \(day) / \(metadata.cycleLength)
        - Next Period Estimated: \(estimatedNextPeriod?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
        """
        
        if let log = todayLog {
            context += "\n\nToday's Logged Data:"
            if let mood = log.mood.state {
                context += "\n- Mood: \(mood.rawValue)"
            }
            context += "\n- Energy Level: \(log.energyLevel)/10"
            
            var symptoms = [String]()
            if log.symptoms.cramps?.isPresent == true { symptoms.append("Cramps") }
            if log.symptoms.bloating?.isPresent == true { symptoms.append("Bloating") }
            if log.symptoms.headache?.isPresent == true { symptoms.append("Headache") }
            if log.symptoms.backPain?.isPresent == true { symptoms.append("Back Pain") }
            if log.symptoms.nausea?.isPresent == true { symptoms.append("Nausea") }
            
            if !symptoms.isEmpty {
                context += "\n- Symptoms: \(symptoms.joined(separator: ", "))"
            }
        }
        
        return context
    }
    
    // MARK: - Insights Engine
    
    private func generateDailyInsight(log: CycleLog) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var explanation = ""
        var whatToExpect = ""
        var tips: [String] = []
        
        // Simple Rule Engine
        switch log.cyclePhase {
        case .menstrual:
            explanation = "Your hormones are at their lowest levels, which causes the uterine lining to shed."
            whatToExpect = "You may feel lower energy and desire more rest."
            tips = ["Prioritize sleep", "Gentle movement like walking", "Warm foods and tea"]
        case .follicular:
            explanation = "Estrogen is rising, boosting your energy and mood."
            whatToExpect = "You might feel more creative and social."
            tips = ["Plan brainstorming sessions", "Try a new workout class", "Socialize with friends"]
        case .ovulation:
            explanation = "Estrogen peaks and testosterone rises slightly."
            whatToExpect = "Confidence and energy are likely high."
            tips = ["High intensity workouts", "Important meetings", "Express your feelings"]
        case .luteal:
            explanation = "Progesterone rises, which can have a calming or sedating effect."
            whatToExpect = "You might turn inward and feel more reflective. PMS symptoms may appear."
            tips = ["Focus on administrative tasks", "Magnesium for cramps", "Reduce caffeine"]
        case .unknown:
            explanation = "Keep tracking to unlock insights."
            whatToExpect = "Consistency is key."
            tips = ["Log your symptoms daily"]
        }
        
        // Symptom specific overrides
        if let cramps = log.symptoms.cramps, cramps.isPresent {
            whatToExpect += " Cramping is common as the uterus contracts."
            tips.append("Use a heat patch or warm bath.")
        }
        
        if let mood = log.mood.state {
            if mood == .anxious || mood == .irritable {
                whatToExpect += " Hormonal fluctuations can impact neurotransmitters."
                tips.append("Try 5 minutes of box breathing.")
            }
        }
        
        let insight = CycleInsight(
            date: log.date,
            explanation: explanation,
            whatToExpect: whatToExpect,
            copingTips: tips,
            confidenceScore: 85
        )
        
        self.todayInsight = insight
        
        // Save Insight
        let id = formatDate(log.date)
        let ref = db.collection("users").document(uid).collection("cycleInsights").document(id)
        try? ref.setData(from: insight, merge: true)
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    
    private func parseDate(_ str: String) -> Date? {
        let f = ISO8601DateFormatter()
        if let d = f.date(from: str) { return d }
        // Try simple format
        let f2 = DateFormatter()
        f2.dateFormat = "yyyy-MM-dd"
        return f2.date(from: str)
    }
}
