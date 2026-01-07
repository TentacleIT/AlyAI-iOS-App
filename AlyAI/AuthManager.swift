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
            
            // Handle login, including potential data migration
            Task {
                await FirestoreManager.shared.handleUserLogin()
            }
        }
    }

    // MARK: - Google Sign In
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
                self?.errorMessage = error?.localizedDescription ?? "Unknown error occurred"
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

    // MARK: - Apple Sign In
    func signInWithApple(authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        guard
            let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let nonce = currentNonce,
            let appleIDToken = appleIDCredential.identityToken,
            let idTokenString = String(data: appleIDToken, encoding: .utf8)
        else {
            errorMessage = "Apple Sign-In failed. Please try again."
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

    // MARK: - Link Apple Account (with safe error handling)
    func linkAppleAccount(authorization: ASAuthorization, completion: @escaping (Bool) -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Apple Authorization failed."
            completion(false)
            return
        }

        guard let nonce = currentNonce else {
            errorMessage = "Invalid state: A login callback was received, but no login nonce was stored. Please try again."
            print("❌ [AuthManager] Error: Nonce was not stored before Apple Sign-In callback")
            completion(false)
            return
        }

        guard let appleIDToken = appleIDCredential.identityToken else {
            errorMessage = "Unable to fetch identity token. Please try again."
            print("❌ [AuthManager] Unable to fetch identity token")
            completion(false)
            return
        }

        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to process identity token. Please try again."
            print("❌ [AuthManager] Unable to serialize token string from data")
            completion(false)
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

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
            ActivityManager.shared.clearLogs()
            NotificationManager.shared.cancelAllNotifications()
            UserDefaults.standard.removeObject(forKey: "userName")

            // 3. Delete Auth Account
            user.delete { error in
                if let error = error {
                    print("❌ Error deleting auth user: \(error)")
                    self.errorMessage = "Failed to delete account: \(error.localizedDescription)"
                    completion(false)
                } else {
                    try? Auth.auth().signOut()
                    completion(true)
                }
            }
        }
    }

    // MARK: - Apple Nonce Helpers
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
