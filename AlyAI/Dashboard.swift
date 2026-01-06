import SwiftUI

struct Dashboard: View {
    
    @EnvironmentObject var userSession: UserSession
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var selectedFeature: SupportPlanItem?
    @State private var showFeatureDetail = false
    @State private var showChat = false
    @State private var showTalk = false
    @State private var showFoodCalculator = false
    @State private var showInsights = false
    @State private var showScheduling = false
    @State private var showProfile = false
    @StateObject private var chatStore = ChatStore()
    @ObservedObject private var activityManager = ActivityManager.shared
    
    // Interactive Activity State
    @State private var selectedAction: RecommendedAction?
    @State private var showActivity = false
    @State private var showCycleDashboard = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {

                headerSection
                
                aiHeroSection
                
                quickActionsSection

                nutritionAndMealsSection // Moved here
                
                // Show Cycle Tracking for female users above Word of the Day
                if let gender = profileManager.currentUserProfile?.userAnswers["gender"] as? String, gender.caseInsensitiveCompare("female") == .orderedSame {
                    cycleTrackingSection
                }

                dailyWordSection

                // The rest of the sections follow
                
                recommendedActionsSection
                
                SupportiveExercisesView()
                
                todaysInsightSection
                
                recentActivitySection
                
                supportPlanSection // Now only shows dynamic items

                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color.backgroundPrimary)
        .sheet(isPresented: $showFeatureDetail) {
            if let feature = selectedFeature, let userAnswers = profileManager.currentUserProfile?.userAnswers {
                SupportFeatureDetailView(feature: feature, userAnswers: userAnswers)
            }
        }
        .sheet(isPresented: $showChat) {
            if let userAnswers = profileManager.currentUserProfile?.userAnswers {
                ChatView(userAnswers: userAnswers, chatStore: chatStore)
            }
        }
        .sheet(isPresented: $showTalk) {
            if let userAnswers = profileManager.currentUserProfile?.userAnswers {
                CallView(userAnswers: userAnswers, chatStore: chatStore)
            }
        }
        .sheet(isPresented: $showFoodCalculator) {
            FoodCalorieCalculatorView()
        }
        .sheet(isPresented: $showInsights) {
            if let userAnswers = profileManager.currentUserProfile?.userAnswers {
                InsightsView(userAnswers: userAnswers)
            }
        }
        .sheet(isPresented: $showScheduling) {
            SchedulingView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showCycleDashboard) {
            CycleTrackingDashboard()
        }
        .fullScreenCover(item: $selectedAction) { action in
            InteractiveActivityView(
                activityType: determineActivityType(for: action),
                title: action.title,
                description: action.description,
                onComplete: { result in
                    Task {
                        await activityManager.logAction(
                            title: action.title,
                            relatedNeed: action.relatedNeed,
                            userInput: result
                        )
                    }
                }
            )
        }
    }

    // MARK: - Today's Insight
    
    @ViewBuilder
    private var todaysInsightSection: some View {
        if let insight = activityManager.todaysInsight {
            DashboardCard(title: "Today's Insight", icon: "lightbulb.fill", iconColor: .warning) {
                Text(insight.summary)
                    .font(.subheadline)
                    .foregroundColor(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(insight.supportingActions.isEmpty ? "Daily Motivation" : "Based on your actions today")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Recommended Actions
    
    @ViewBuilder
    private var recommendedActionsSection: some View {
        if let actions = profileManager.currentUserProfile?.assessmentResult.recommendedActions, !actions.isEmpty {
            DashboardCard(title: "Your Recommended Actions", icon: "list.star", iconColor: .accentPrimary) {
                ForEach(actions) { action in
                    actionCard(action: action)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    private func actionCard(action: RecommendedAction) -> some View {
        let isCompleted = activityManager.isActionCompletedToday(title: action.title)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Content remains the same, just the outer container is now the DashboardCard
            HStack {
                Text(action.title)
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text(action.priority.capitalized)
                    .font(.caption).fontWeight(.bold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(priorityColor(action.priority).opacity(0.2)))
                    .foregroundColor(priorityColor(action.priority))
            }
            Text(action.description)
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                if !action.suggestedFrequency.isEmpty {
                    Label(action.suggestedFrequency, systemImage: "clock").font(.caption).foregroundColor(Color.textSecondary)
                }
                Spacer()
                if isCompleted {
                    // ... completed button
                } else {
                    Button("Start") { selectedAction = action }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentPrimary)
                }
            }
            if !action.relatedNeed.isEmpty {
                Text("Supports: " + action.relatedNeed).font(.caption2).foregroundColor(Color.textSecondary.opacity(0.8))
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.backgroundPrimary))
    }
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .error
        case "medium": return .warning
        default: return .accentPrimary
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AlyAI")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.textPrimary)

                Text("Your AI life companion")
                    .font(.subheadline)
                    .foregroundColor(Color.textPrimary.opacity(0.8))
            }

            Spacer()

            Button {
                showProfile = true
            } label: {
                Circle()
                    .fill(Color.surfacePrimary)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(Color.textPrimary)
                    )
            }
        }
    }

    // MARK: - AI Hero Section (Inspired by Image)

    private var aiHeroSection: some View {
        let name = userSession.userName
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        
        let displayGreeting = name.isEmpty ? timeGreeting : "\(timeGreeting), \(name)"

        return RoundedRectangle(cornerRadius: 26)
            .fill(Color.surfacePrimary)
            .frame(height: 220)
            .shadow(color: Color.shadow, radius: 10, x: 0, y: 5)
            .overlay(
                VStack(spacing: 20) {

                    VStack(spacing: 6) {
                        Text(displayGreeting)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("I'm here for you. How would you like to connect?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }

                    HStack(spacing: 16) {

                        aiPrimaryButton(
                            title: "Talk to Me",
                            subtitle: "Speak & vent",
                            icon: "phone.fill",
                            color: .alyaiEmotional // Emotional orange
                        ) {
                            showTalk = true
                        }

                        aiPrimaryButton(
                            title: "Let us Chat",
                            subtitle: "Type & reflect",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .alyaiMental // Core purple
                        ) {
                            showChat = true
                        }
                    }
                }
                .padding()
            )
    }

    // MARK: - Cycle Tracking
    
    @ViewBuilder
    private var cycleTrackingSection: some View {
        // This view is already a card, just needs tap gesture
        CycleTrackingView()
            .onTapGesture { showCycleDashboard = true }
    }

    // MARK: - Daily Word

    private var dailyWordSection: some View {
        let name = userSession.userName
        let quote = DailyWordManager.shared.getQuote(userName: name)
        
        return DashboardCard(title: "Word of the Day", icon: "quote.opening", iconColor: .accentPrimary) {
            Text(quote)
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundColor(Color.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("- Your Companion")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Quick Actions (Inspired by Card Grid)

    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            dashboardActionCard(
                title: "Scheduling",
                subtitle: "Set reminders & structure",
                icon: "calendar.badge.clock",
                color: .alyaiPhysical // Productive green
            ) { showScheduling = true }

            dashboardActionCard(
                title: "Calorie Calculator",
                subtitle: "Snap & track meals",
                icon: "camera.viewfinder",
                color: .error // Health red
            ) { showFoodCalculator = true }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        DashboardCard(title: "Recent Activity", icon: "bubble.left.and.bubble.right", iconColor: .alySecondary, hasMore: true, moreAction: {}) {
            VStack(spacing: 12) {
                recentChatRow(title: "Feeling mentally overwhelmed", subtitle: "We explored grounding strategies")
                recentChatRow(title: "Planning a healthier routine", subtitle: "ALYAI suggested small steps")
            }
        }
    }

    // MARK: - Support Plan

    @ViewBuilder
    private var nutritionAndMealsSection: some View {
        supportRow(
            title: "Nutrition & Meals",
            subtitle: "Flexible, non-restrictive guidance",
            icon: "fork.knife",
            color: .alyaiPhysical
        )
    }

    @ViewBuilder
    private var supportPlanSection: some View {
        // Show this card only if there are dynamic support items
        if let plan = profileManager.currentUserProfile?.supportPlan, !plan.isEmpty {
            DashboardCard(title: "Your Support Areas", icon: "square.stack.3d.up.fill", iconColor: .alyaiPhysical) {
                VStack(spacing: 14) {
                    ForEach(plan) { item in
                        supportRow(title: item.title, subtitle: item.description ?? "", icon: item.icon, color: .accentPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func aiPrimaryButton(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = .accentPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .padding(.bottom, 2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold) // Sharper text
                    .foregroundColor(Color.textPrimary)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                ZStack {
                    // Base shape
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.backgroundPrimary)
                    
                    // Inner top highlight for sheen
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .padding(1)

                    // Subtle inner bottom shadow for depth
                     VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.04)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 10)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .shadow(color: Color.shadow.opacity(0.18), radius: 10, x: 0, y: 5) // Deeper shadow
            )
        }
    }

    private func dashboardActionCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color = .accentPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {

                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(color)
                    .padding(8)
                    .background(Circle().fill(color.opacity(0.1)))

                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.surfacePrimary)
                    .shadow(color: Color.shadow, radius: 12, x: 0, y: 6)
            )
        }
    }

    private func recentChatRow(title: String, subtitle: String, isAction: Bool = false) -> some View {
        HStack {
            Image(systemName: isAction ? "checkmark.circle.fill" : "bubble.left.fill")
                .font(.system(size: 16))
                .foregroundColor(isAction ? Color.accentPrimary : Color.alySecondary)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.backgroundPrimary))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(Color.textPrimary)
                Text(subtitle).font(.caption).foregroundColor(Color.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(Color.textSecondary)
        }
    }

    private func determineActivityType(for action: RecommendedAction) -> ActivityType {
        let title = action.title.lowercased()
        let need = action.relatedNeed.lowercased()
        
        // Check specific activity types in title first
        if title.contains("sleep") || title.contains("wind") {
            return .sleep
        } else if title.contains("breath") {
            return .anxiety
        } else if title.contains("meditat") || title.contains("mindful") {
            return .mindfulness
        } else if title.contains("think") || title.contains("thought") || title.contains("refram") {
            return .cognitive
        } else if title.contains("mood") || title.contains("track") {
            return .mood
        } else if title.contains("affirm") || title.contains("positive") {
            return .affirmation
        }
        
        // Fallback based on need
        if need.contains("sleep") {
            return .sleep
        } else if need.contains("anxiety") || need.contains("panic") {
            return .anxiety
        } else if need.contains("overthinking") {
            return .cognitive
        }
        
        return .generic
    }

    private func supportRow(title: String, subtitle: String, icon: String, color: Color = .accentPrimary) -> some View {
        Button {
            selectedFeature = SupportPlanItem(title: title, icon: icon)
            showFeatureDetail = true
        } label: {
            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(color.opacity(0.1)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.textSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.surfacePrimary)
                    .shadow(color: Color.shadow, radius: 12, x: 0, y: 6)
            )
        }
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    var iconColor: Color = .accentPrimary
    var hasMore: Bool = false
    var moreAction: (() -> Void)? = nil
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundColor(iconColor)
                Spacer()
                if hasMore {
                    Button("View all") { moreAction?() }
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.surfacePrimary)
                .shadow(color: Color.shadow.opacity(0.1), radius: 10, y: 5)
        )
    }
}

#Preview {
    Group {
        Dashboard()
            .environmentObject(UserSession())
            .environmentObject(UserProfileManager.shared)
        Dashboard()
            .preferredColorScheme(.dark)
            .environmentObject(UserSession())
            .environmentObject(UserProfileManager.shared)
    }
}
