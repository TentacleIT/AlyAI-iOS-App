import SwiftUI
import UIKit

struct SubscriptionView: View {

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Header
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.warning)
                        .padding(.top)

                    Text("Unlock Full Potential")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Get personalized insights, unlimited chats, and advanced cycle tracking.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.textSecondary)
                        .padding(.horizontal)
                }

                // MARK: - Current Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Status")
                        .font(.headline)
                        .foregroundColor(Color.textSecondary)

                    HStack {
                        Text(subscriptionManager.isSubscribed ? "Premium Active" : "Free Plan")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        if subscriptionManager.isSubscribed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.success)
                        }
                    }
                    .padding()
                    .background(Color.surfacePrimary)
                    .cornerRadius(12)
                    .shadow(color: Color.shadow, radius: 5)
                }
                .padding(.horizontal)

                // MARK: - Plans
                if !subscriptionManager.isSubscribed {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Plans")
                            .font(.headline)
                            .foregroundColor(Color.textSecondary)

                        Button {
                            // 🔥 Trigger Superwall Paywall
                            subscriptionManager.presentPaywallIfNeeded()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("View Plans")
                                        .font(.headline)
                                        .foregroundColor(Color.textPrimary)

                                    Text("Start your 7-day free trial")
                                        .font(.subheadline)
                                        .foregroundColor(Color.textSecondary)
                                }

                                Spacer()

                                Text("Upgrade")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.backgroundPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.accentPrimary)
                                    .cornerRadius(20)
                            }
                            .padding()
                            .background(Color.surfacePrimary)
                            .cornerRadius(12)
                            .shadow(color: Color.shadow, radius: 5)
                        }
                    }
                    .padding(.horizontal)
                } else {

                    // MARK: - Manage Subscription
                    Button("Manage Subscription") {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundColor(Color.accentPrimary)
                    .padding()
                }

                Spacer()

                // MARK: - Legal
                VStack(spacing: 8) {
                    Text("Recurring billing. Cancel anytime.")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)

                    HStack {
                        Button("Terms of Service") {}
                        Text("•")
                        Button("Privacy Policy") {}
                    }
                    .font(.caption)
                    .foregroundColor(Color.accentPrimary)
                }
                .padding(.bottom)
            }
            .padding()
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Subscription")

        // MARK: - Auto Gate (Post-Login)
        .onAppear {
            if !subscriptionManager.isSubscribed {
                subscriptionManager.presentPaywallIfNeeded()
            }
        }
    }
}

#Preview {
    SubscriptionView()
}
