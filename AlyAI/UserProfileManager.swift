import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

struct UserProfile: Codable {
    var answersData: Data
    var assessmentResult: AssessmentResult
    var supportPlan: [SupportPlanItem]
    
    var userAnswers: [String: Any] {
        get {
            if let dict = try? JSONSerialization.jsonObject(with: answersData) as? [String: Any] {
                return dict
            }
            return [:]
        }
        set {
            if let data = try? JSONSerialization.data(withJSONObject: newValue) {
                answersData = data
            }
        }
    }
    
    init(answers: [String: Any], assessmentResult: AssessmentResult, supportPlan: [SupportPlanItem]) {
        self.assessmentResult = assessmentResult
        self.supportPlan = supportPlan
        self.answersData = (try? JSONSerialization.data(withJSONObject: answers)) ?? Data()
    }
}

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var currentUserProfile: UserProfile?
    @Published var voicePreference: TherapistVoicePreference = .default
    private let userDefaultsKey = "user_profile_data"
    private let voiceDefaultsKey = "therapist_voice_preference"

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if user != nil {
                Task {
                    await self?.loadProfile()
                    await self?.loadVoicePreference()
                }
            } else {
                self?.currentUserProfile = nil
                self?.voicePreference = .default
            }
        }
    }

    func saveProfile(answers: [String: Any], result: AssessmentResult, plan: [SupportPlanItem]) async {
        let profile = UserProfile(answers: answers, assessmentResult: result, supportPlan: plan)
        do {
            let data = try Firestore.Encoder().encode(profile)
            try await FirestoreManager.shared.saveUserData(data, in: "profile", docId: "main")
            self.currentUserProfile = profile
        } catch {
            print("❌ Error saving profile: \(error)")
        }
    }
    
    func loadProfile() async {
        guard let document = await FirestoreManager.shared.fetchUserDocument(from: "profile", docId: "main") else {
            self.currentUserProfile = nil
            return
        }

        if document.exists {
            do {
                self.currentUserProfile = try document.data(as: UserProfile.self)
            } catch {
                print("❌ Error decoding profile: \(error)")
            }
        }
    }
    
    func clearProfile() {
        self.currentUserProfile = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    func loadLegacyProfileFromUserDefaults() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }
    
    // MARK: - Voice Preference
    
    func saveVoicePreference(_ preference: TherapistVoicePreference) async {
        do {
            let data = try Firestore.Encoder().encode(preference)
            try await FirestoreManager.shared.saveUserData(data, in: "preferences", docId: "therapistVoice")
            self.voicePreference = preference
            
            // Cache locally
            if let encoded = try? JSONEncoder().encode(preference) {
                UserDefaults.standard.set(encoded, forKey: voiceDefaultsKey)
            }
        } catch {
            print("❌ Error saving voice preference: \(error)")
        }
    }
    
    func loadVoicePreference() async {
        // Try local cache first for immediate UI update
        if let data = UserDefaults.standard.data(forKey: voiceDefaultsKey),
           let cached = try? JSONDecoder().decode(TherapistVoicePreference.self, from: data) {
            self.voicePreference = cached
        }
        
        // Then fetch from Firestore
        guard let document = await FirestoreManager.shared.fetchUserDocument(from: "preferences", docId: "therapistVoice") else {
            return
        }

        if document.exists {
            do {
                let remote = try document.data(as: TherapistVoicePreference.self)
                self.voicePreference = remote
                
                // Update local cache
                if let encoded = try? JSONEncoder().encode(remote) {
                    UserDefaults.standard.set(encoded, forKey: voiceDefaultsKey)
                }
            } catch {
                print("❌ Error decoding voice preference: \(error)")
            }
        }
    }
}
