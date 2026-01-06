import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.error)
                    .padding(.top)
                
                Text("Delete Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("This action is permanent and cannot be undone.")
                        .font(.headline)
                        .foregroundColor(Color.error)
                    
                    Text("The following data will be permanently deleted:")
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("User profile and settings")
                        bulletPoint("Onboarding answers & assessments")
                        bulletPoint("Mood & Cycle tracking data")
                        bulletPoint("Chat history & insights")
                        bulletPoint("Health data derived from Apple Watch")
                    }
                    .padding(.leading)
                }
                .padding()
                .background(Color.surfacePrimary)
                .cornerRadius(12)
                .shadow(color: Color.shadow, radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("To confirm, please type DELETE below:")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    TextField("Type DELETE", text: $deleteConfirmationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                }
                .padding()
                
                Button {
                    performDelete()
                } label: {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.backgroundPrimary))
                    } else {
                        Text("Permanently Delete Account")
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidConfirmation ? Color.error : Color.textSecondary)
                .foregroundColor(Color.backgroundPrimary)
                .cornerRadius(12)
                .disabled(!isValidConfirmation || isDeleting)
                
                Spacer()
            }
            .padding()
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Delete Account")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var isValidConfirmation: Bool {
        return deleteConfirmationText == "DELETE"
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
            Text(text)
        }
        .foregroundColor(Color.textSecondary)
    }
    
    private func performDelete() {
        isDeleting = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            AuthManager.shared.deleteAccount { success in
                isDeleting = false
                if success {
                    // Force app restart or navigation to Onboarding
                    // Since we are in a subview, simple dismiss might not work if root view doesn't update.
                    // But AuthManager clears data. We need ContentView to react.
                    // For now, dismiss, and user might see broken UI until restart, unless we fix ContentView.
                    dismiss()
                } else {
                    alertMessage = "Failed to delete account. Please try again."
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        DeleteAccountView()
    }
}
