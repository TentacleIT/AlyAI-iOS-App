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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(personalizationContext.getPersonalizedGreeting())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.alyTextPrimary)
                            
                            Text(getContextualSubheading())
                                .font(.caption)
                                .foregroundColor(.alyTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Quick stats indicator
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption)
                                Text(personalizationContext.energyLevel)
                                    .font(.caption2)
                            }
                            .foregroundColor(.alyaiPhysical)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                    .font(.caption)
                                Text(personalizationContext.sleepQuality)
                                    .font(.caption2)
                            }
                            .foregroundColor(.alyaiMental)
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
                    .cornerRadius(12)
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Goals")
                                    .font(.headline)
                                    .foregroundColor(.alyTextPrimary)
                                
                                ForEach(personalizationContext.primaryGoals.prefix(3), id: \.self) { goal in
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundColor(.alyaiPhysical)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(goal)
                                                .font(.body)
                                                .foregroundColor(.alyTextPrimary)
                                            
                                            Text(getGoalRecommendation(for: goal))
                                                .font(.caption)
                                                .foregroundColor(.alyTextSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.alyCard)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.alyCard)
                            .cornerRadius(12)
                        }
                        
                        // Needs-Based Recommendations
                        if !personalizationContext.greatestNeeds.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Personalized for Your Needs")
                                    .font(.headline)
                                    .foregroundColor(.alyTextPrimary)
                                
                                ForEach(personalizationContext.greatestNeeds.prefix(2), id: \.self) { need in
                                    NeedBasedRecommendationCard(need: need, context: personalizationContext)
                                }
                            }
                            .padding()
                            .background(Color.alyCard)
                            .cornerRadius(12)
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 100)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.alyTextPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.alyTextSecondary)
                .lineLimit(3)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.1),
                    color.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.alyTextSecondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.alyTextPrimary)
            
            Text(recommendation)
                .font(.caption2)
                .foregroundColor(.alyTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.alyCard)
        .cornerRadius(12)
    }
}

// MARK: - Need-Based Recommendation Card
struct NeedBasedRecommendationCard: View {
    let need: String
    let context: PersonalizationContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(need)
                    .font(.headline)
                    .foregroundColor(.alyTextPrimary)
                
                Spacer()
                
                Image(systemName: getIconForNeed(need))
                    .foregroundColor(getColorForNeed(need))
            }
            
            Text(getRecommendationForNeed(need))
                .font(.caption)
                .foregroundColor(.alyTextSecondary)
        }
        .padding()
        .background(Color.alyBackground)
        .cornerRadius(8)
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
