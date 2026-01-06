import SwiftUI

struct NotificationsView: View {
    @StateObject private var manager = NotificationManager.shared
    
    var body: some View {
        Form {
            if !manager.isPermissionGranted {
                Section {
                    Button("Enable Notifications") {
                        manager.requestPermission()
                    }
                } footer: {
                    Text("Please enable notifications in settings to receive timely insights.")
                }
            }
            
            Section(header: Text("Delivery Channels")) {
                Toggle("Push Notifications", isOn: $manager.preferences.pushEnabled)
                Toggle("In-App Banners", isOn: $manager.preferences.inAppEnabled)
                Toggle("Email Updates", isOn: $manager.preferences.emailEnabled)
                    .disabled(true) // Email not yet supported
            }
            
            Section(header: Text("Notification Types")) {
                let modules = ["Health", "Mood", "AI", "Cycle", "Subscription", "System"]
                ForEach(modules, id: \.self) { module in
                    Toggle(module, isOn: bindingForModule(module))
                }
            }
            
            Section(footer: Text("AlyAI uses AI to send personalized, relevant notifications. You can control which types of notifications you receive.")) { }
        }
        .navigationTitle("Notifications")
        .onChange(of: manager.preferences.pushEnabled) { _ in manager.savePreferences() }
        .onChange(of: manager.preferences.inAppEnabled) { _ in manager.savePreferences() }
        .onChange(of: manager.preferences.emailEnabled) { _ in manager.savePreferences() }
        .onAppear {
            manager.checkPermission()
        }
    }
    
    private func bindingForModule(_ module: String) -> Binding<Bool> {
        return Binding<Bool>(
            get: { manager.preferences.moduleOptIn.contains(module) },
            set: { isEnabled in
                if isEnabled {
                    if !manager.preferences.moduleOptIn.contains(module) {
                        manager.preferences.moduleOptIn.append(module)
                    }
                } else {
                    manager.preferences.moduleOptIn.removeAll { $0 == module }
                }
                manager.savePreferences()
            }
        )
    }
}

#Preview {
    NotificationsView()
}
