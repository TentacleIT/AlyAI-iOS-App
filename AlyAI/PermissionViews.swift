import SwiftUI

struct HealthPermissionView: View {
    var onContinue: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon / Illustration
            ZStack {
                Circle()
                    .fill(Color.error.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "applewatch.watchface")
                    .font(.system(size: 80))
                    .foregroundColor(Color.error)
            }
            
            VStack(spacing: 16) {
                Text("Connect Apple Watch")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text("AlyAI uses your Apple Watch data to understand stress patterns, sleep quality, and emotional wellbeing — so it can support you more thoughtfully.\n\nYour data stays private and is never shared.")
                    .font(.body)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                isProcessing = true
                HealthKitManager.shared.requestAuthorization { success in
                    DispatchQueue.main.async {
                        isProcessing = false
                        onContinue()
                    }
                }
            } label: {
                if isProcessing {
                    ProgressView()
                        .tint(Color.backgroundPrimary)
                } else {
                    Text("Allow Apple Watch Access")
                }
            }
            .buttonStyle(AlyPrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            Button("Not Now") {
                onContinue()
            }
            .font(.subheadline)
            .foregroundColor(Color.textSecondary)
            .padding(.bottom)
        }
        .padding()
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }
}

struct NotificationPermissionView: View {
    var onContinue: () -> Void
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon / Illustration
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.accentPrimary)
            }
            
            VStack(spacing: 16) {
                Text("Stay Supported")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("AlyAI sends gentle reminders when:")
                        .font(.body)
                        .foregroundColor(Color.textSecondary)
                    
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Color.textSecondary)
                        Text("Your cycle phase is approaching")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                    }
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Color.textSecondary)
                        Text("It’s time for reflection or care")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                    }
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(Color.textSecondary)
                        Text("Your mood patterns need support")
                            .font(.body)
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Text("\nYou’re always in control.")
                        .font(.body)
                        .foregroundColor(Color.textSecondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                isProcessing = true
                NotificationManager.shared.requestPermission { granted in
                    DispatchQueue.main.async {
                        isProcessing = false
                        onContinue()
                    }
                }
            } label: {
                if isProcessing {
                    ProgressView()
                } else {
                    Text("Allow Notifications")
                }
            }
            .buttonStyle(AlyPrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            Button("Not Now") {
                onContinue()
            }
            .font(.subheadline)
            .foregroundColor(Color.textSecondary)
            .padding(.bottom)
        }
        .padding()
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }
}
