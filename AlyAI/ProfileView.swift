import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var healthManager = HealthKitManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.accentPrimary)
                            .padding(.top, 20)
                        
                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.textPrimary)
                        
                        if let gender = profileManager.currentUserProfile?.userAnswers["gender_identity"] as? String {
                            Text(gender)
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    
                    // Account Security Section
                    accountSecuritySection

                    // Profile Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Profile Information")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            profileRow(title: "Name", value: displayName)
                            Divider().background(Color.textSecondary.opacity(0.3))
                            if let email = authManager.user?.email {
                                profileRow(title: "Email", value: email)
                                Divider().background(Color.textSecondary.opacity(0.3))
                            }
                        }
                        .background(Color.surfacePrimary)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preferences")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: TherapistVoiceView()) {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(Color.accentPrimary)
                                        .frame(width: 24)
                                    Text("Therapist Voice")
                                        .foregroundColor(Color.textPrimary)
                                    Spacer()
                                    
                                    // Show current selection name (simplified logic for display)
                                    Text(profileManager.voicePreference.voiceId.contains("sarah") ? "Sarah" : "Daniel")
                                        .font(.subheadline)
                                        .foregroundColor(Color.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color.textSecondary)
                                }
                                .padding()
                            }
                        }
                        .background(Color.surfacePrimary)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Subscription Section
                    // ... (rest of the view remains the same) ...
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Subscription")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(Color.warning)
                                    .frame(width: 24)
                                Text("Current Plan")
                                    .foregroundColor(Color.textPrimary)
                                Spacer()
                                Text("Free")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.textSecondary)
                            }
                            .padding()
                            
                            Divider().background(Color.textSecondary.opacity(0.3))
                            
                            NavigationLink(destination: SubscriptionView()) {
                                HStack {
                                    Text("Manage Subscription")
                                        .foregroundColor(Color.accentPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color.textSecondary)
                                }
                                .padding()
                            }
                        }
                        .background(Color.surfacePrimary)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Account Management Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: DeleteAccountView()) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(Color.error)
                                        .frame(width: 24)
                                    Text("Delete Account")
                                        .foregroundColor(Color.error)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.textSecondary)
                                        .font(.caption)
                                }
                                .padding()
                            }
                        }
                        .background(Color.surfacePrimary)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.bottom)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.accentPrimary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var accountSecuritySection: some View {
        if let user = authManager.user {
            VStack(alignment: .leading, spacing: 16) {
                Text("Account Security")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    // Check for Apple provider
                    if !user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                                let nonce = AuthManager.shared.randomNonceString()
                                request.nonce = AuthManager.shared.sha256(nonce)
                                AuthManager.shared.currentNonce = nonce
                            },
                            onCompletion: { result in
                                switch result {
                                case .success(let authorization):
                                    AuthManager.shared.linkAppleAccount(authorization: authorization) { success in
                                        if !success {
                                            // Handle error if needed
                                        }
                                    }
                                case .failure(let error):
                                    print("Apple Linking Error: \(error.localizedDescription)")
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 55)
                        .padding()
                    }
                }
                .background(Color.surfacePrimary)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(Color.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(Color.textSecondary)
        }
        .padding()
    }
    
    private var displayName: String {
        userSession.userName.isEmpty ? "ALYAI User" : userSession.userName
    }
}
