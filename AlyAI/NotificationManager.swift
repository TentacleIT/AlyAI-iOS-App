import Foundation
import Combine
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var preferences: NotificationPreferences = NotificationPreferences()
    @Published var sentNotifications: [SentNotification] = []
    @Published var isPermissionGranted = false

    private var db = Firestore.firestore()
    private var preferencesListener: ListenerRegistration?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermission()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if user != nil {
                self?.attachPreferencesListener()
            } else {
                self?.preferencesListener?.remove()
                self?.preferences = NotificationPreferences()
                self?.sentNotifications = []
            }
        }
    }
    
    // MARK: - Permissions
    
    func requestPermission(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
                completion(granted)
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isPermissionGranted = (settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Preferences Management

    private func attachPreferencesListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        preferencesListener?.remove() // Detach old listener
        let docRef = db.collection("users").document(uid).collection("notifications").document("preferences")
        
        preferencesListener = docRef.addSnapshotListener { [weak self] (document, error) in
            guard let self = self else { return }
            if let document = document, document.exists {
                if let prefs = try? document.data(as: NotificationPreferences.self) {
                    self.preferences = prefs
                }
            } else {
                // No preferences saved yet, create default
                self.savePreferences()
            }
        }
    }
    
    func savePreferences() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        preferences.lastUpdated = Date()
        
        do {
            try db.collection("users").document(uid).collection("notifications").document("preferences").setData(from: preferences)
        } catch {
            print("Error saving notification preferences: \(error)")
        }
    }
    
    // MARK: - AI Notification Generation

    func generateAndScheduleNotifications() {
        let context = gatherContext()
        let prompt = buildPrompt(context: context)
        
        OpenAIService.shared.runAssessment(prompt: prompt, jsonMode: true) { [weak self] response in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                guard let data = response.data(using: .utf8),
                      let generated = try? JSONDecoder().decode([SentNotification].self, from: data) else {
                    print("Failed to decode AI-generated notifications")
                    return
                }
                
                for notification in generated {
                    self.saveAndSchedule(notification: notification)
                }
            }
        }
    }
    
    private func gatherContext() -> [String: String] {
        var context: [String: String] = [:]
        
        context["timezone"] = TimeZone.current.identifier
        context["cyclePhase"] = CycleManager.shared.currentPhase.rawValue
        context["mood"] = NutritionManager.shared.getCurrentMood()
        // ... add more context from other managers
        
        return context
    }
    
    private func buildPrompt(context: [String: String]) -> String {
        let optInModules = preferences.moduleOptIn.joined(separator: ", ")
        
        return """
        You are an AI assistant for AlyAI, a women's wellness app.
        Your task is to generate a batch of personalized, actionable notifications for a user.

        USER CONTEXT:
        - Timezone: \(context["timezone"]!)
        - Opted-in Modules: [\(optInModules)]
        - Cycle Phase: \(context["cyclePhase"] ?? "N/A")
        - Current Mood: \(context["mood"] ?? "N/A")

        INSTRUCTIONS:
        1. Generate a few (2-3) relevant notifications based on the user's context.
        2. Prioritize modules the user has opted into.
        3. If cycle phase is available, generate a cycle-related notification.
        4. If a trial is ending soon (hypothetically, you can assume this for now), generate a subscription reminder.
        5. Keep the tone friendly, supportive, and not spammy.

        OUTPUT FORMAT (Strict JSON array):
        [
            {
                "type": "Cycle",
                "content": "It’s your follicular phase! A great time for a high-energy workout.",
                "actionLink": "alyai://activity/workouts",
                "urgency": "Routine",
                "context": ["\(context["cyclePhase"]!)"]
            },
            {
                "type": "Subscription",
                "content": "Your trial ends in 3 days. Subscribe now to keep your progress!",
                "actionLink": "alyai://subscription",
                "urgency": "Important",
                "context": ["TrialEnd"]
            }
        ]
        """
    }
    
    // MARK: - Scheduling & Persistence
    
    private func saveAndSchedule(notification: SentNotification) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        var mutableNotification = notification
        
        // Save to Firestore
        do {
            let ref = try db.collection("users").document(uid).collection("notifications").document("sentNotifications").collection("history").addDocument(from: mutableNotification)
            mutableNotification.id = ref.documentID
            DispatchQueue.main.async {
                self.sentNotifications.insert(mutableNotification, at: 0)
            }
        } catch {
            print("Error saving notification: \(error)")
            return
        }
        
        // Schedule if push is enabled
        if preferences.pushEnabled {
            // For AI-generated notifications, schedule them for a few seconds in the future.
            // A more advanced implementation would have the AI suggest a delivery time.
            let scheduleDate = Date().addingTimeInterval(5)
            scheduleLocalNotification(notification: mutableNotification, at: scheduleDate)
        }
    }
    
    func scheduleLocalNotification(notification: SentNotification, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "AlyAI"
        content.body = notification.content
        content.sound = .default
        content.userInfo = ["actionLink": notification.actionLink ?? ""]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: notification.id ?? UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func markAsRead(notificationId: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid).collection("notifications").document("sentNotifications").collection("history").document(notificationId)
        docRef.updateData(["readStatus": true])
        
        if let index = sentNotifications.firstIndex(where: { $0.id == notificationId }) {
            sentNotifications[index].readStatus = true
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All pending notifications have been cancelled.")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle foreground notifications
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle user tapping on a notification
        let userInfo = response.notification.request.content.userInfo
        if let actionLink = userInfo["actionLink"] as? String {
            print("Handle deep link: \(actionLink)")
            // Post a notification to be handled by the app's coordinator
            NotificationCenter.default.post(name: .handleDeepLink, object: URL(string: actionLink))
        }
        completionHandler()
    }
}

extension Notification.Name {
    static let handleDeepLink = Notification.Name("handleDeepLink")
}
