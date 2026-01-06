import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class AppointmentManager: ObservableObject {
    static let shared = AppointmentManager()
    
    @Published var appointments: [Appointment] = []
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if user != nil {
                self?.loadAppointments()
            } else {
                self?.clearAppointments()
            }
        }
    }
    
    func loadAppointments() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        listener?.remove()
        let query = db.collection("users").document(uid).collection("appointments").order(by: "scheduledDateTime", descending: true)
        
        listener = query.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching appointments: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self?.appointments = documents.compactMap { document -> Appointment? in
                var appointment = try? document.data(as: Appointment.self)
                appointment?.id = document.documentID
                return appointment
            }
        }
    }
    
    func createAppointment(appointment: Appointment, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AppAuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."]))
            return
        }
        
        do {
            let ref = try db.collection("users").document(uid).collection("appointments").addDocument(from: appointment)
            
            // Schedule notification
            scheduleReminder(for: appointment, withId: ref.documentID)
            
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func updateAppointmentStatus(appointmentId: String, newStatus: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = db.collection("users").document(uid).collection("appointments").document(appointmentId)
        
        docRef.updateData([
            "status": newStatus,
            "updatedAt": Date()
        ]) { error in
            if let error = error {
                print("Error updating appointment: \(error)")
            } else {
                if newStatus == "Cancelled" {
                    // Cancel associated notification
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [appointmentId])
                }
            }
        }
    }
    
    private func scheduleReminder(for appointment: Appointment, withId appointmentId: String) {
        // Schedule reminder 1 hour before
        if let reminderDate = Calendar.current.date(byAdding: .hour, value: -1, to: appointment.scheduledDateTime) {
            let notification = SentNotification(
                id: appointmentId, // Use appointment ID for notification ID
                type: "Appointment",
                content: "You have an appointment with your \(appointment.specialistType) in 1 hour.",
                actionLink: "alyai://appointment/\(appointmentId)",
                urgency: "Important",
                context: ["AppointmentReminder"]
            )
            NotificationManager.shared.scheduleLocalNotification(notification: notification, at: reminderDate)
        }
    }
    
    func clearAppointments() {
        listener?.remove()
        appointments = []
    }
}
