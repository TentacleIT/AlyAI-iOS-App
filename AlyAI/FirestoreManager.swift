import FirebaseFirestore
import FirebaseAuth
import UIKit // Needed for UIDevice

@MainActor
class FirestoreManager {
    static let shared = FirestoreManager()
    private let db = Firestore.firestore()

    func handleUserLogin() async {
        guard let user = Auth.auth().currentUser else { return }
        let userDocRef = db.collection("users").document(user.uid)

        do {
            let metadataDoc = try await userDocRef.collection("metadata").document("data").getDocument()

            if !metadataDoc.exists {
                print("MIGRATING...")
                await migrateLocalDataToFirestore(for: user.uid)
            }

            await createOrUpdateUserProfile(uid: user.uid)
            
            // Check if PersonalizationContext needs migration
            await migratePersonalizationContextIfNeeded(for: user.uid)

        } catch {
            print("Error checking for user metadata: \(error). Assuming new user and migrating.")
            await migrateLocalDataToFirestore(for: user.uid)
            await createOrUpdateUserProfile(uid: user.uid)
            await migratePersonalizationContextIfNeeded(for: user.uid)
        }
    }

    private func createOrUpdateUserProfile(uid: String) async {
        guard let user = Auth.auth().currentUser else { return }
        let data: [String: Any] = [
            "uid": uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "",
            "providerIds": user.providerData.map { $0.providerID },
            "createdAt": FieldValue.serverTimestamp(),
            "lastLogin": FieldValue.serverTimestamp()
        ]

        do {
            try await db.collection("users").document(uid).collection("profile").document("data").setData(data, merge: true)
        } catch {
            print("❌ Firestore error saving profile: \(error)")
        }
    }

    private func migrateLocalDataToFirestore(for uid: String) async {
        print("BEGIN: Migrating local UserDefaults data to Firestore for user \(uid)")

        if let profile = UserProfileManager.shared.loadLegacyProfileFromUserDefaults() {
            do {
                let onboardingData: [String: Any] = [
                    "primaryGoal": (profile.userAnswers["main_goal"] as? [String] ?? []).joined(separator: ", "),
                    "customGoals": "",
                    "needs": (profile.userAnswers["greatest_need"] as? [String] ?? []).joined(separator: ", "),
                    "assessmentSummary": profile.assessmentResult.summary
                ]
                try await db.collection("users").document(uid).collection("onboarding").document("data").setData(onboardingData)
                let assessmentData = try Firestore.Encoder().encode(profile.assessmentResult)
                try await db.collection("users").document(uid).setData(["assessment": assessmentData], merge: true)
            } catch {
                print("❌ Failed to migrate user profile/onboarding: \(error)")
            }
        }

        if let logs = ActivityManager.shared.loadLegacyLogs() {
            let batch = db.batch()
            for log in logs {
                let ref = db.collection("users").document(uid).collection("actionLogs").document()
                do {
                    try batch.setData(from: log, forDocument: ref)
                } catch {
                    print("❌ Error setting log data in batch: \(error)")
                }
            }
            do {
                try await batch.commit()
            } catch {
                print("❌ Failed to commit actionLogs batch: \(error)")
            }
        }

        if let insights = ActivityManager.shared.loadLegacyInsights() {
            let batch = db.batch()
            for insight in insights {
                let ref = db.collection("users").document(uid).collection("dailyInsights").document(insight.date.formatted(.iso8601))
                do {
                    try batch.setData(from: insight, forDocument: ref)
                } catch {
                    print("❌ Error setting insight data in batch: \(error)")
                }
            }
            do {
                try await batch.commit()
            } catch {
                print("❌ Failed to commit dailyInsights batch: \(error)")
            }
        }

        if let history = NutritionManager.shared.loadLegacyHistory() {
            let batch = db.batch()
            for item in history {
                let ref = db.collection("users").document(uid).collection("mealHistory").document(item.date)
                do {
                    try batch.setData(from: item, forDocument: ref)
                } catch {
                    print("❌ Error setting meal history data in batch: \(error)")
                }
            }
            do {
                try await batch.commit()
            } catch {
                print("❌ Failed to commit mealHistory batch: \(error)")
            }
        }

        do {
            try await db.collection("users").document(uid).collection("metadata").document("data").setData(["migrationCompleted": true], merge: true)
        } catch {
            print("❌ Failed to mark migration as complete: \(error)")
        }
    }

    func saveUserData(_ data: [String: Any], in collection: String, docId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).collection(collection).document(docId).setData(data, merge: true)
    }

    func fetchUserCollection(_ collection: String) async -> [QueryDocumentSnapshot]? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        do {
            let snapshot = try await db.collection("users").document(uid).collection(collection).getDocuments()
            return snapshot.documents
        } catch {
            print("❌ Failed to fetch collection \(collection): \(error)")
            return nil
        }
    }

    func fetchUserDocument(from collection: String, docId: String) async -> DocumentSnapshot? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        do {
            let snapshot = try await db.collection("users").document(uid).collection(collection).document(docId).getDocument()
            return snapshot
        } catch {
            print("❌ Failed to fetch document \(docId) from \(collection): \(error)")
            return nil
        }
    }
    
    func updateDeviceToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

        let device = Device(
            fcmToken: token,
            appVersion: appVersion
        )

        let docRef = db.collection("users").document(uid).collection("devices").document(deviceId)

        do {
            try docRef.setData(from: device, merge: true)
        } catch {
            print("❌ Error saving device token to Firestore: \(error)")
        }
    }

    /// Migrate PersonalizationContext for existing users who have profile but no personalization document
    private func migratePersonalizationContextIfNeeded(for uid: String) async {
        // Check if personalization document exists
        let personalizationDoc = try? await db.collection("users").document(uid).collection("personalization").document("context").getDocument()
        
        if personalizationDoc?.exists == true {
            print("✅ PersonalizationContext already exists, no migration needed")
            return
        }
        
        // Check if profile exists
        guard let profileDoc = try? await db.collection("users").document(uid).collection("profile").document("main").getDocument(),
              profileDoc.exists else {
            print("⚠️ No profile found for PersonalizationContext migration")
            return
        }
        
        print("🔄 Migrating PersonalizationContext for existing user")
        
        // PersonalizationContext will auto-load from profile and save to Firestore
        // when UserProfileManager loads the profile and triggers the isProfileLoaded event
        // No explicit action needed here - the reactive system handles it
    }
    
    func deleteUserData(for uid: String) async {
        print("🗑️ Deleting user data for \(uid)...")

        let collections = [
            "metadata",
            "profile",
            "onboarding",
            "preferences",
            "personalization", // Personalization context data
            "cycleData",
            "cycleLogs",
            "cycleInsights",
            "actionLogs",
            "dailyInsights",
            "mealHistory",
            "devices"
        ]

        for collectionName in collections {
            let colRef = db.collection("users").document(uid).collection(collectionName)
            await deleteCollection(colRef)
        }

        // Delete the main user document
        do {
            try await db.collection("users").document(uid).delete()
            print("✅ Deleted user document")
        } catch {
            print("❌ Failed to delete user document: \(error)")
        }
    }

    private func deleteCollection(_ collectionRef: CollectionReference, batchSize: Int = 500) async {
        do {
            let snapshot = try await collectionRef.limit(to: batchSize).getDocuments()
            guard !snapshot.documents.isEmpty else { return }

            let batch = db.batch()
            for doc in snapshot.documents {
                batch.deleteDocument(doc.reference)
            }
            try await batch.commit()
            print("✅ Deleted batch from \(collectionRef.path)")

            if snapshot.documents.count >= batchSize {
                await deleteCollection(collectionRef, batchSize: batchSize)
            }
        } catch {
            print("❌ Error deleting collection \(collectionRef.path): \(error)")
        }
    }
}
