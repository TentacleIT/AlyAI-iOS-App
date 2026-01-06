import Foundation
import SwiftUI
import Combine
import UIKit
import SuperwallKit

// MARK: - Quick Action Types

enum QuickAction: String {
    case sendFeedback
    case tryForFree
}

@MainActor
class QuickActionService: ObservableObject {
    static let shared = QuickActionService()

    // For handling shortcuts when the app is already running
    @Published var selectedAction: QuickAction? = nil
    
    // For handling shortcuts on cold launch
    static var initialAction: QuickAction? = nil

    private init() {}

    // MARK: - Register Quick Actions

    func updateQuickActions() {
        var shortcuts: [UIApplicationShortcutItem] = []

        // 1️⃣ "Deleting? Tell us why?" — Always visible
        let feedbackShortcut = UIApplicationShortcutItem(
            type: QuickAction.sendFeedback.rawValue,
            localizedTitle: "Deleting? Tell us why?",
            localizedSubtitle: "Send feedback before you delete",
            icon: UIApplicationShortcutIcon(systemImageName: "square.and.pencil")
        )
        shortcuts.append(feedbackShortcut)

        // 2️⃣ "🎁 TRY FOR FREE" — Only for non-subscribed users
        if !SubscriptionManager.shared.isSubscribed {
            let freeTrialShortcut = UIApplicationShortcutItem(
                type: QuickAction.tryForFree.rawValue,
                localizedTitle: "🎁 TRY FOR FREE",
                localizedSubtitle: "Get unlimited access to AlyAI",
                icon: UIApplicationShortcutIcon(systemImageName: "gift.fill")
            )
            shortcuts.append(freeTrialShortcut)
        }

        UIApplication.shared.shortcutItems = shortcuts
        print("✅ Quick Actions Updated. Count: \(shortcuts.count)")
    }

    // MARK: - Handle Quick Action

    func handleShortcutItem(_ item: UIApplicationShortcutItem) -> Bool {
        guard let action = QuickAction(rawValue: item.type) else {
            return false
        }

        // Store for cold launch handling
        QuickActionService.initialAction = action

        // Handle immediately if app is warm
        self.selectedAction = action

        // Execute action
        route(action)

        print("🚀 Handling Quick Action: \(action.rawValue)")
        return true
    }

    // MARK: - Routing Logic

    private func route(_ action: QuickAction) {
        switch action {

        case .tryForFree:
            triggerFreeTrialPaywall()

        case .sendFeedback:
            openFeedbackFlow()
        }
    }

    // MARK: - Superwall Free Trial Trigger

    private func triggerFreeTrialPaywall() {
        /*
         IMPORTANT:
         - This placement ID MUST match the campaign you create in Superwall
         - Example campaign name: "home_icon_free_trial"
        */
        Superwall.shared.register(
            placement: "home_icon_free_trial"
        )
    }

    // MARK: - Feedback Routing (Stub)

    private func openFeedbackFlow() {
        // Route to in-app feedback screen or external form
        // Navigation intentionally left flexible
        print("📝 Opening feedback flow")
    }
}
