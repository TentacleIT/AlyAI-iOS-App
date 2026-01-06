import Foundation
import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var user: User?
    @Published var errorMessage: String?
    
    var currentNonce: String?

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            
            if let user = user {
                // Identify user in Superwall
                SubscriptionManager.shared.identifyUser(uid: user.uid)
                AppointmentManager.shared.loadAppointments()
            } else {
                SubscriptionManager.shared.reset()
                AppointmentManager.shared.clearAppointments()
            }
            
            guard let user = user else { return }
            
            // Save display name locally if available
            if let displayName = user.displayName, !displayName.isEmpty {
                let defaults = UserDefaults.standard
                if defaults.string(forKey: "userName")?.isEmpty ?? true {
                    defaults.set(displayName, forKey: "userName")
                }
            }
            
            // 🔥 Handle login, including potential data migration
            Task {
                await FirestoreManager.shared.handleUserLogin()
            }
        }
    }

    // ---- Google Sign In (UNCHANGED) ----
    func signInWithGoogle(rootViewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Client ID in Firebase Configuration."
            completion(false)
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard error == nil,
                  let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.errorMessage = error?.localizedDescription
                completion(false)
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    // ---- Apple Sign In (UNCHANGED LOGIC) ----
    func signInWithApple(authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            errorMessage = "Apple Sign-In failed."
            completion(false)
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        Auth.auth().signIn(with: credential) { _, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func linkAppleAccount(authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Apple Authorization failed."
            completion(false)
            return
        }

        guard let nonce = currentNonce else {
            fatalError("Invalid state: A login callback was received, but no login nonce was stored.")
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetch identity token")
            return
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialize token string from data: \(appleIDCredential.debugDescription)")
            return
        }

        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)

        Auth.auth().currentUser?.link(with: credential) { (authResult, error) in
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("❌ [AuthManager] Error linking Apple account: \(error)")
                completion(false)
                return
            }

            print("✅ [AuthManager] Successfully linked Apple account.")
            completion(true)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        SubscriptionManager.shared.reset()
    }

    func deleteAccount(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }

        let uid = user.uid

        Task {
            // 1. Delete Firestore Data
            await FirestoreManager.shared.deleteUserData(for: uid)

            // 2. Clear Local Data
            UserProfileManager.shared.clearProfile()
            // CycleManager.shared.clearData() // This is now handled by FirestoreManager.deleteUserData
            ActivityManager.shared.clearLogs()
            NotificationManager.shared.cancelAllNotifications()
            UserDefaults.standard.removeObject(forKey: "userName")

            // 3. Delete Auth Account
            user.delete { error in
                if let error = error {
                    print("❌ Error deleting auth user: \(error)")
                    completion(false)
                } else {
                    try? Auth.auth().signOut()
                    completion(true)
                }
            }
        }
    }

    // ---- Apple Nonce Helpers (UNCHANGED) ----
    func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        while result.count < length {
            var random: UInt8 = 0
            SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
            }
        }
        return result
    }

    func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
