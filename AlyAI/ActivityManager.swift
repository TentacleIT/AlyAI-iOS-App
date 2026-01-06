import Foundation
import Combine
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ActionLog: Codable, Identifiable {
    @DocumentID var id: String?
    let actionTitle: String
    let relatedNeed: String
    let completionDate: Date
    let userInput: String? // Mood note, journal entry, etc.
    let duration: TimeInterval?
    
    var simpleDescription: String {
        if let input = userInput, !input.isEmpty {
             return "Completed a `\(actionTitle)` at \(completionDate.formatted(date: .omitted, time: .shortened)). Note: \(input)"
        }
        return "Completed `\(actionTitle)` at \(completionDate.formatted(date: .omitted, time: .shortened))"
    }
}

struct DailyInsight: Codable, Identifiable {
    @DocumentID var id: String?
    let date: Date
    let summary: String
    let supportingActions: [String]
    let emotionalSignal: String?
}

@MainActor
class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    @Published var dailyLogs: [ActionLog] = []
    @Published var dailyInsights: [DailyInsight] = []
    
    private var db = Firestore.firestore()
    private var logsListener: ListenerRegistration?
    private var insightsListener: ListenerRegistration?
    private let logsUserDefaultsKey = "daily_action_logs"
    private let insightsUserDefaultsKey = "daily_insights"

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.subscribe(for: user.uid)
            } else {
                self?.unsubscribe()
            }
        }
    }
    
    func subscribe(for uid: String) {
        unsubscribe()

        let logsCollection = db.collection("users").document(uid).collection("actionLogs").order(by: "completionDate", descending: true).limit(to: 100)
        logsListener = logsCollection.addSnapshotListener { [weak self] (querySnapshot, error) in
            self?.dailyLogs = querySnapshot?.documents.compactMap { try? $0.data(as: ActionLog.self) } ?? []
        }

        let insightsCollection = db.collection("users").document(uid).collection("dailyInsights").order(by: "date", descending: true).limit(to: 30)
        insightsListener = insightsCollection.addSnapshotListener { [weak self] (querySnapshot, error) in
            self?.dailyInsights = querySnapshot?.documents.compactMap { try? $0.data(as: DailyInsight.self) } ?? []
        }
    }

    private func unsubscribe() {
        logsListener?.remove()
        insightsListener?.remove()
        dailyLogs = []
        dailyInsights = []
    }
    
    func logAction(title: String, relatedNeed: String, userInput: String? = nil, duration: TimeInterval? = nil) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let log = ActionLog(
            actionTitle: title,
            relatedNeed: relatedNeed,
            completionDate: Date(),
            userInput: userInput,
            duration: duration
        )
        
        do {
            _ = try db.collection("users").document(uid).collection("actionLogs").addDocument(from: log)
            await generateAndSaveTodaysInsight()
        } catch {
            print("Error saving action log: \(error)")
        }
    }
    
    func isActionCompletedToday(title: String) -> Bool {
        let calendar = Calendar.current
        return dailyLogs.contains { log in
            log.actionTitle == title && calendar.isDateInToday(log.completionDate)
        }
    }
    
    var todaysInsight: DailyInsight? {
        let calendar = Calendar.current
        return dailyInsights.first { calendar.isDateInToday($0.date) }
    }
    
    private func generateAndSaveTodaysInsight() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // ... (insight generation logic is complex and assumed correct) ...
        let insight = DailyInsight(date: Date(), summary: "Generated Insight", supportingActions: [], emotionalSignal: nil) // Placeholder
        
        let insightDocRef = db.collection("users").document(uid).collection("dailyInsights").document(Date().formatted(.iso8601))
        do {
            try await insightDocRef.setData(from: insight, merge: true)
        } catch {
            print("Error saving insight: \(error)")
        }
    }
    
    func loadLegacyLogs() -> [ActionLog]? {
        guard let data = UserDefaults.standard.data(forKey: logsUserDefaultsKey) else { return nil }
        return try? JSONDecoder().decode([ActionLog].self, from: data)
    }

    func loadLegacyInsights() -> [DailyInsight]? {
        guard let data = UserDefaults.standard.data(forKey: insightsUserDefaultsKey) else { return nil }
        return try? JSONDecoder().decode([DailyInsight].self, from: data)
    }

    func clearLogs() {
        // This would now be a more complex deletion from Firestore if needed
    }

    func getHistoryForOpenAI() -> String {
        let calendar = Calendar.current
        let today = Date()
        guard let last7Days = calendar.date(byAdding: .day, value: -7, to: today) else { return "" }
        
        var context = "User Insights & Activity History (Last 7 Days):\n"
        
        let recentInsights = dailyInsights.filter { $0.date >= last7Days }
        if !recentInsights.isEmpty {
            context += "\nDaily Insights:\n"
            for insight in recentInsights {
                let dayStr = insight.date.formatted(date: .abbreviated, time: .omitted)
                context += "- \(dayStr): \(insight.summary)\n"
            }
        }
        
        let recentLogs = dailyLogs.filter { $0.completionDate >= last7Days }
        if !recentLogs.isEmpty {
            context += "\nDetailed Activity Log:\n"
            let grouped = Dictionary(grouping: recentLogs) { log in
                calendar.startOfDay(for: log.completionDate)
            }
            let sortedDays = grouped.keys.sorted()
            for day in sortedDays {
                let dayStr = day.formatted(date: .abbreviated, time: .omitted)
                context += "- \(dayStr):\n"
                if let logs = grouped[day] {
                    for log in logs {
                        context += "  * \(log.simpleDescription)\n"
                    }
                }
            }
        } else if recentInsights.isEmpty {
             context += "No recent activity or insights recorded."
        }
        
        if HealthKitManager.shared.isAuthorized {
            context += "\nHealth Context (Current):\n"
            context += "- Steps: \(HealthKitManager.shared.stepCount)\n"
            context += "- Sleep: \(String(format: "%.1f", HealthKitManager.shared.sleepHours)) hours\n"
            context += "- Heart Rate: \(Int(HealthKitManager.shared.latestHeartRate)) bpm\n"
            context += "- HRV: \(Int(HealthKitManager.shared.hrv)) ms\n"
        }
        
        return context
    }
}
