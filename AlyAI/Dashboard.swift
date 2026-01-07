import SwiftUI

struct Dashboard_Enhanced: View {
    @ObservedObject var personalizationContext = PersonalizationContext.shared
    @ObservedObject var profileManager = UserProfileManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTab: Int = 0
    @State private var showChat = false
    
    var body: some View {
        ZStack {
            Color.alyBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Personalized Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(personalizationContext.getPersonalizedGreeting())
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.alyTextPrimary)
                            
                            Text(getContextualSubheading())
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.alyTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Quick stats indicator
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(personalizationContext.energyLevel)
                                    .font(.system(size: 13, weight: .semibold))
                                    .textCase(.lowercase)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.alyaiPhysical.opacity(0.15))
                            .foregroundColor(.alyaiPhysical)
                            .cornerRadius(12)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(personalizationContext.sleepQuality)
                                    .font(.system(size: 13, weight: .semibold))
                                    .textCase(.lowercase)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.alyaiMental.opacity(0.15))
                            .foregroundColor(.alyaiMental)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.alyaiPrimary.opacity(0.1),
                                Color.alyaiEmotional.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                .padding()
                
                // MARK: - Quick Action Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionButton(
                            icon: "message.fill",
                            title: "Talk to AlyAI",
                            color: .alyaiPrimary,
                            action: { showChat = true }
                        )
                        
                        if personalizationContext.greatestNeeds.contains("Fitness") ||
                           personalizationContext.primaryGoals.contains("Exercise") {
                            QuickActionButton(
                                icon: "figure.walk",
                                title: "Activity",
                                color: .alyaiPhysical,
                                action: {}
                            )
                        }
                        
                        if personalizationContext.greatestNeeds.contains("Nutrition") ||
                           personalizationContext.primaryGoals.contains("Nutrition") {
                            QuickActionButton(
                                icon: "fork.knife",
                                title: "Nutrition",
                                color: .alyaiPhysical,
                                action: {}
                            )
                        }
                        
                        if personalizationContext.gender.lowercased() == "female" {
                            QuickActionButton(
                                icon: "heart.circle.fill",
                                title: "Cycle",
                                color: .alyaiEmotional,
                                action: {}
                            )
                        }
                        
                        if personalizationContext.greatestNeeds.contains("Sleep") ||
                           personalizationContext.sleepQuality.lowercased().contains("poor") {
                            QuickActionButton(
                                icon: "moon.zzz.fill",
                                title: "Sleep",
                                color: .alyaiMental,
                                action: {}
                            )
                        }
                    }
                    .padding()
                }
                
                // MARK: - Personalized Insights Section
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Focus Card
                        PersonalizedInsightCard(
                            title: "Your Current Focus",
                            subtitle: personalizationContext.currentFocus,
                            icon: "target",
                            color: .alyaiPrimary,
                            content: getContextualInsight()
                        )
                        
                        // Stress & Energy Status
                        HStack(spacing: 12) {
                            PersonalizedMetricCard(
                                title: "Stress Level",
                                value: personalizationContext.stressLevel,
                                icon: "brain.head.profile",
                                color: .alyaiMental,
                                recommendation: getStressRecommendation()
                            )
                            
                            PersonalizedMetricCard(
                                title: "Energy",
                                value: personalizationContext.energyLevel,
                                icon: "bolt.fill",
                                color: .alyaiPhysical,
                                recommendation: getEnergyRecommendation()
                            )
                        }
                        
                        // Goals Progress
                        if !personalizationContext.primaryGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Your Goals")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.alyTextPrimary)
                                
                                ForEach(personalizationContext.primaryGoals.prefix(3), id: \.self) { goal in
                                    HStack(spacing: 14) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundColor(.alyaiPhysical)
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(goal)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.alyTextPrimary)
                                            
                                            Text(getGoalRecommendation(for: goal))
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.alyTextSecondary)
                                                .lineSpacing(1)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(Color.alyCard)
                                    .cornerRadius(14)
                                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                                }
                            }
                            .padding(18)
                            .background(Color.alyCard.opacity(0.5))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                        
                        // Needs-Based Recommendations
                        if !personalizationContext.greatestNeeds.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Personalized for Your Needs")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.alyTextPrimary)
                                
                                ForEach(personalizationContext.greatestNeeds.prefix(2), id: \.self) { need in
                                    NeedBasedRecommendationCard(need: need, context: personalizationContext)
                                }
                            }
                            .padding(18)
                            .background(Color.alyCard.opacity(0.5))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
            
            // Chat Sheet
            if showChat {
                ChatView_Enhanced(
                    userAnswers: profileManager.currentUserProfile?.userAnswers ?? [:],
                    chatStore: ChatStore()
                )
                .transition(.move(edge: .bottom))
            }
        }
    }
    
    private func getContextualSubheading() -> String {
        if personalizationContext.stressLevel.lowercased().contains("high") {
            return "Let's focus on what matters most to you today"
        } else if personalizationContext.energyLevel.lowercased().contains("low") {
            return "Take it easy and be kind to yourself"
        } else {
            return "You're doing great! Keep up the momentum"
        }
    }
    
    private func getContextualInsight() -> String {
        let focus = personalizationContext.currentFocus
        let needs = personalizationContext.greatestNeeds
        
        if focus.lowercased().contains("mental") {
            return "Focus on activities that calm your mind and reduce stress"
        } else if focus.lowercased().contains("physical") {
            return "Incorporate movement and nutrition that energizes you"
        } else if needs.contains("Sleep") {
            return "Prioritize rest and recovery for better overall wellness"
        } else {
            return "Balance is key - take care of your mind, body, and emotions"
        }
    }
    
    private func getStressRecommendation() -> String {
        let level = personalizationContext.stressLevel.lowercased()
        if level.contains("high") {
            return "Try a breathing exercise or meditation"
        } else if level.contains("moderate") {
            return "Consider a short walk or stretching"
        } else {
            return "Keep maintaining your wellness routine"
        }
    }
    
    private func getEnergyRecommendation() -> String {
        let level = personalizationContext.energyLevel.lowercased()
        if level.contains("low") {
            return "Rest or light activity recommended"
        } else if level.contains("moderate") {
            return "Good time for regular activities"
        } else {
            return "Great time for challenging activities"
        }
    }
    
    private func getGoalRecommendation(for goal: String) -> String {
        let lowerGoal = goal.lowercased()
        if lowerGoal.contains("fitness") || lowerGoal.contains("exercise") {
            return "Schedule 30 minutes of your preferred activity"
        } else if lowerGoal.contains("nutrition") || lowerGoal.contains("diet") {
            return "Plan your meals based on your preferences"
        } else if lowerGoal.contains("sleep") {
            return "Maintain a consistent sleep schedule"
        } else if lowerGoal.contains("stress") || lowerGoal.contains("anxiety") {
            return "Practice mindfulness or relaxation techniques"
        } else {
            return "Take one small step toward this goal today"
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 110, height: 110)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Personalized Insight Card
struct PersonalizedInsightCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.alyTextPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                        .textCase(.lowercase)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
                    .padding(12)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Text(content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.alyTextSecondary)
                .lineLimit(3)
                .lineSpacing(2)
        }
        .padding(18)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.08),
                    color.opacity(0.03)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Personalized Metric Card
struct PersonalizedMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let recommendation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.alyTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.alyTextPrimary)
                .textCase(.lowercase)
            
            Text(recommendation)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.alyTextSecondary)
                .lineLimit(2)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.alyCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Need-Based Recommendation Card
struct NeedBasedRecommendationCard: View {
    let need: String
    let context: PersonalizationContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: getIconForNeed(need))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(getColorForNeed(need))
                    .padding(10)
                    .background(getColorForNeed(need).opacity(0.15))
                    .clipShape(Circle())
                
                Text(need)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.alyTextPrimary)
                
                Spacer()
            }
            
            Text(getRecommendationForNeed(need))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.alyTextSecondary)
                .lineSpacing(1)
        }
        .padding(14)
        .background(Color.alyCard)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
    
    private func getIconForNeed(_ need: String) -> String {
        let lower = need.lowercased()
        if lower.contains("fitness") || lower.contains("exercise") {
            return "figure.walk"
        } else if lower.contains("nutrition") || lower.contains("food") {
            return "fork.knife"
        } else if lower.contains("sleep") {
            return "moon.zzz.fill"
        } else if lower.contains("stress") || lower.contains("anxiety") {
            return "brain.head.profile"
        } else if lower.contains("social") || lower.contains("connection") {
            return "person.2.fill"
        } else {
            return "heart.fill"
        }
    }
    
    private func getColorForNeed(_ need: String) -> Color {
        let lower = need.lowercased()
        if lower.contains("fitness") || lower.contains("exercise") {
            return .alyaiPhysical
        } else if lower.contains("stress") || lower.contains("anxiety") {
            return .alyaiMental
        } else {
            return .alyaiEmotional
        }
    }
    
    private func getRecommendationForNeed(_ need: String) -> String {
        let lower = need.lowercased()
        let energyLevel = context.energyLevel.lowercased()
        
        if lower.contains("fitness") || lower.contains("exercise") {
            if energyLevel.contains("low") {
                return "Try light stretching or a short walk today"
            } else {
                return "Great time for your preferred workout"
            }
        } else if lower.contains("nutrition") || lower.contains("food") {
            if context.dietaryPreferences.isEmpty {
                return "Plan meals that nourish your body"
            } else {
                return "Enjoy meals that fit your preferences: \(context.dietaryPreferences.first ?? "")"
            }
        } else if lower.contains("sleep") {
            return "Aim for 7-9 hours tonight for optimal recovery"
        } else if lower.contains("stress") || lower.contains("anxiety") {
            return "Practice a calming technique like meditation"
        } else if lower.contains("social") || lower.contains("connection") {
            return "Reach out to someone you care about"
        } else {
            return "Focus on this area that matters to you"
        }
    }
}

#Preview {
    Dashboard_Enhanced()
}
