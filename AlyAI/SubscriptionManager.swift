import Foundation
import Combine
import SuperwallKit
import StoreKit
import UIKit

@MainActor
final class SubscriptionManager: ObservableObject {

    static let shared = SubscriptionManager()

    // MARK: - Published State
    @Published var isSubscribed: Bool = false

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        observeSubscriptionStatus()
    }

    // MARK: - Observe Subscription State
    private func observeSubscriptionStatus() {
        Superwall.shared.$subscriptionStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                guard let self else { return }

                switch status {
                case .active:
                    self.isSubscribed = true
                case .inactive, .unknown:
                    self.isSubscribed = false
                @unknown default:
                    self.isSubscribed = false
                }

                print("🔔 Superwall Subscription Status: \(status)")

                // Update home screen quick actions based on subscription status
                QuickActionService.shared.updateQuickActions()
            }
            .store(in: &cancellables)
    }

    // MARK: - Identify User
    func identifyUser(uid: String) {
        Superwall.shared.identify(userId: uid)

        // Optional attributes
        Superwall.shared.setUserAttributes([
            "platform": "ios",
            "auth_provider": "apple_google"
        ])
        
        // Sync age-based attributes on login
        syncUserAttributesFromStorage()
    }

    // MARK: - Logout Reset
    func reset() {
        Superwall.shared.reset()
        isSubscribed = false
    }

    // MARK: - Paywall Trigger (Post Auth)
    /// Call immediately after Google / Apple sign-in succeeds
    func presentPaywallIfNeeded() {
        // DEVELOPMENT OVERRIDE
        if FeatureFlags.disablePaywallForDevelopment {
            print("⚠️ DEV MODE: Skipping Superwall paywall trigger.")
            return
        }

        guard !isSubscribed else {
            print("✅ User already subscribed — skipping paywall")
            return
        }

        // MUST match placement name in Superwall Dashboard
        Superwall.shared.register(placement: "post_auth_paywall")
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        let result = await Superwall.shared.restorePurchases()

        switch result {
        case .restored:
            print("✅ Purchases restored successfully")
        case .failed(let error):
            print("❌ Restore failed: \(error)")
        }
    }

    // MARK: - Age-Based Segmentation

    func handleOnboardingCompletion(dob: Date) {
        let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
        let ageGroup: String

        switch age {
        case ..<18:
            ageGroup = "under18"
        case 18...22:
            ageGroup = "age18to22"
        case 23...28:
            ageGroup = "age23to28"
        case 29...40:
            ageGroup = "age29to40"
        default:
            ageGroup = "over40"
        }

        // Persist values locally
        let defaults = UserDefaults.standard
        defaults.set(age, forKey: "userAge")
        defaults.set(ageGroup, forKey: "userAgeGroup")
        print("✅ Stored userAge: \(age) and userAgeGroup: \(ageGroup)")

        // Set Superwall attributes and register placement
        let attributes: [String: Any] = ["age": age, "age_group": ageGroup]
        Superwall.shared.setUserAttributes(attributes)
        
        print("✅ Registering Superwall placement: \(ageGroup) for age: \(age)")
        Superwall.shared.register(placement: ageGroup)
    }

    private func syncUserAttributesFromStorage() {
        let defaults = UserDefaults.standard
        let age = defaults.integer(forKey: "userAge")
        let ageGroup = defaults.string(forKey: "userAgeGroup")

        if age > 0, let ageGroup = ageGroup, !ageGroup.isEmpty {
            print("🔄 Syncing stored user attributes to Superwall: age \(age), age_group \(ageGroup)")
            let attributes: [String: Any] = ["age": age, "age_group": ageGroup]
            Superwall.shared.setUserAttributes(attributes)
        } else {
            print("🤷 No stored user attributes to sync.")
        }
    }
}
