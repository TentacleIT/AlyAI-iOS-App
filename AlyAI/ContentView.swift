import SwiftUI
import SuperwallKit

struct ContentView: View {
    @State private var showSplash = true
    @ObservedObject private var profileManager = UserProfileManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quickActionService = QuickActionService.shared
    
    // State for handling quick actions
    @State private var showFeedbackSheet = false
    @State private var showPaywallFromShortcut: Bool
    @State private var isDevModeForcedOnboarding = false

    init() {
        // Handle cold launch from a shortcut
        if QuickActionService.initialAction == .tryForFree {
            self._showPaywallFromShortcut = State(initialValue: true)
        } else {
            self._showPaywallFromShortcut = State(initialValue: false)
        }
    }
    
    var body: some View {
        ZStack {
            Color.alyBackground.ignoresSafeArea()
            
            if showPaywallFromShortcut {
                SubscriptionView()
            } else if showSplash {
                SplashView(onComplete: {
                    #if DEBUG
                    // SANDBOX / TESTING MODE:
                    print("DEBUG: Sandbox mode detected. Forcing Onboarding.")
                    isDevModeForcedOnboarding = true
                    #endif
                    
                    showSplash = false
                })
            } else if profileManager.currentUserProfile != nil && !isDevModeForcedOnboarding {
                // Check for subscription OR development flag
                if subscriptionManager.isSubscribed || FeatureFlags.disablePaywallForDevelopment {
                    Dashboard()
                } else {
                    NavigationView {
                        SubscriptionView()
                    }
                }
            } else {
                OnboardingView(onComplete: { answers, result, plan in
                    Task {
                        await UserProfileManager.shared.saveProfile(answers: answers, result: result, plan: plan)
                    }
                    isDevModeForcedOnboarding = false
                    
                    // New Superwall Logic
                    registerSuperwallPlacement(answers: answers)
                })
            }
        }
        .onChange(of: quickActionService.selectedAction) { action in
            guard let action = action else { return }
            switch action {
            case .sendFeedback:
                showFeedbackSheet = true
            case .tryForFree:
                // This handles the warm launch case
                showPaywallFromShortcut = true
            }
            // Reset the action so it can be consumed again
            quickActionService.selectedAction = nil
        }
        .sheet(isPresented: $showFeedbackSheet) {
            // TODO: Replace with a real feedback view
            VStack {
                Text("Send Feedback").font(.largeTitle).padding()
                Text("We appreciate you taking the time to share your thoughts.").padding()
                Button("Close") { showFeedbackSheet = false }.padding()
            }
        }
    }

    private func registerSuperwallPlacement(answers: [String: Any]) {
        // DEVELOPMENT OVERRIDE
        if FeatureFlags.disablePaywallForDevelopment {
            print("⚠️ DEV MODE: Skipping Superwall placement registration after onboarding.")
            return
        }

        guard let dob = answers["dob"] as? Date else {
            // Fallback for safety, though DOB is required in onboarding
            print("⚠️ Could not find DOB in onboarding answers to determine age group for paywall.")
            Superwall.shared.register(placement: "post_auth_paywall")
            return
        }
        
        SubscriptionManager.shared.handleOnboardingCompletion(dob: dob)
    }
}
