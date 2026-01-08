import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var healthManager = HealthKitManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var personalizationContext = PersonalizationContext.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showSignOutAlert = false
    @State private var showDataExportSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Personal Information Section
                    personalInfoSection
                    
                    // Goals & Needs Section
                    goalsAndNeedsSection
                    
                    // App Permissions Section
                    permissionsSection
                    
                    // Preferences Section
                    preferencesSection
                    
                    // Subscription Section
                    subscriptionSection
                    
                    // Data & Privacy Section
                    dataPrivacySection
                    
                    // Account Actions Section
                    accountActionsSection
                    
                    // App Info Section
                    appInfoSection
                    
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
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showDataExportSheet) {
                DataExportView()
            }
        }
    }
    
    // MARK: - Profile Header
    
    @ViewBuilder
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentPrimary.opacity(0.3), Color.accentPrimary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentPrimary)
            }
            .padding(.top, 20)
            
            Text(displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.textPrimary)
            
            if !personalizationContext.gender.isEmpty {
                Text(personalizationContext.gender.capitalized)
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
            }
            
            if let email = authManager.user?.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
    }
    
    // MARK: - Personal Information Section
    
    @ViewBuilder
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                profileRow(icon: "person.fill", title: "Name", value: displayName)
                Divider().background(Color.textSecondary.opacity(0.3))
                
                if let email = authManager.user?.email {
                    profileRow(icon: "envelope.fill", title: "Email", value: email)
                    Divider().background(Color.textSecondary.opacity(0.3))
                }
                
                if !personalizationContext.gender.isEmpty {
                    profileRow(icon: "person.2.fill", title: "Gender", value: personalizationContext.gender.capitalized)
                    Divider().background(Color.textSecondary.opacity(0.3))
                }
                
                if !personalizationContext.country.isEmpty {
                    profileRow(icon: "globe", title: "Country", value: personalizationContext.country)
                }
            }
            .background(Color.surfacePrimary)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Goals & Needs Section
    
    @ViewBuilder
    private var goalsAndNeedsSection: some View {
        if !personalizationContext.greatestNeeds.isEmpty || !personalizationContext.currentFocus.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Journey")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    if !personalizationContext.currentFocus.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(Color.accentPrimary)
                                Text("Current Focus")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.textPrimary)
                            }
                            Text(personalizationContext.currentFocus)
                                .font(.body)
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfacePrimary)
                        .cornerRadius(12)
                    }
                    
                    if !personalizationContext.greatestNeeds.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(Color.accentPrimary)
                                Text("Greatest Needs")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.textPrimary)
                            }
                            
                            ForEach(personalizationContext.greatestNeeds, id: \.self) { need in
                                HStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(Color.accentPrimary)
                                    Text(need)
                                        .font(.body)
                                        .foregroundColor(Color.textSecondary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.surfacePrimary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Permissions Section
    
    @ViewBuilder
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Permissions")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                permissionRow(
                    icon: "heart.fill",
                    title: "Health Data",
                    status: healthManager.isAuthorized ? "Enabled" : "Disabled",
                    statusColor: healthManager.isAuthorized ? .success : .textSecondary
                )
                Divider().background(Color.textSecondary.opacity(0.3))
                
                permissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    status: notificationManager.isAuthorized ? "Enabled" : "Disabled",
                    statusColor: notificationManager.isAuthorized ? .success : .textSecondary
                )
                Divider().background(Color.textSecondary.opacity(0.3))
                
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(Color.accentPrimary)
                            .frame(width: 24)
                        Text("Manage in Settings")
                            .foregroundColor(Color.accentPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
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
    }
    
    // MARK: - Preferences Section
    
    @ViewBuilder
    private var preferencesSection: some View {
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
    }
    
    // MARK: - Subscription Section
    
    @ViewBuilder
    private var subscriptionSection: some View {
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
    }
    
    // MARK: - Data & Privacy Section
    
    @ViewBuilder
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data & Privacy")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button(action: {
                    showDataExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "arrow.down.doc")
                            .foregroundColor(Color.accentPrimary)
                            .frame(width: 24)
                        Text("Export My Data")
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding()
                }
                
                Divider().background(Color.textSecondary.opacity(0.3))
                
                NavigationLink(destination: Text("Privacy Policy")) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(Color.accentPrimary)
                            .frame(width: 24)
                        Text("Privacy Policy")
                            .foregroundColor(Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding()
                }
                
                Divider().background(Color.textSecondary.opacity(0.3))
                
                NavigationLink(destination: Text("Terms of Service")) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.accentPrimary)
                            .frame(width: 24)
                        Text("Terms of Service")
                            .foregroundColor(Color.textPrimary)
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
    }
    
    // MARK: - Account Actions Section
    
    @ViewBuilder
    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button(action: {
                    showSignOutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(Color.warning)
                            .frame(width: 24)
                        Text("Sign Out")
                            .foregroundColor(Color.warning)
                        Spacer()
                    }
                    .padding()
                }
                
                Divider().background(Color.textSecondary.opacity(0.3))
                
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
    }
    
    // MARK: - App Info Section
    
    @ViewBuilder
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                profileRow(icon: "info.circle", title: "Version", value: appVersion)
                Divider().background(Color.textSecondary.opacity(0.3))
                
                NavigationLink(destination: Text("Support & Help")) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(Color.accentPrimary)
                            .frame(width: 24)
                        Text("Support & Help")
                            .foregroundColor(Color.textPrimary)
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
    }
    
    // MARK: - Helper Views
    
    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.accentPrimary)
                .frame(width: 24)
            Text(title)
                .foregroundColor(Color.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(Color.textSecondary)
        }
        .padding()
    }
    
    private func permissionRow(icon: String, title: String, status: String, statusColor: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.accentPrimary)
                .frame(width: 24)
            Text(title)
                .foregroundColor(Color.textPrimary)
            Spacer()
            Text(status)
                .font(.subheadline)
                .foregroundColor(statusColor)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var displayName: String {
        if !personalizationContext.userName.isEmpty {
            return personalizationContext.userName
        } else if !userSession.userName.isEmpty {
            return userSession.userName
        } else {
            return "ALYAI User"
        }
    }
    
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }
    
    // MARK: - Actions
    
    private func signOut() {
        authManager.signOut()
        dismiss()
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportComplete = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.accentPrimary)
                    .padding(.top, 40)
                
                Text("Export Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("Download a copy of all your data including profile information, wellness assessments, cycle tracking data, and meditation progress.")
                    .font(.body)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if exportComplete {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.success)
                        
                        Text("Export Complete!")
                            .font(.headline)
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Your data has been prepared and will be sent to your email.")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Export Data")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            exportComplete = true
            
            // TODO: Implement actual data export logic
            // - Collect all user data from Firestore
            // - Generate JSON/CSV file
            // - Send via email or provide download link
        }
    }
}
