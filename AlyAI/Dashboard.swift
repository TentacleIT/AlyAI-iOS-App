import SwiftUI

struct Dashboard_Enhanced: View {
    @ObservedObject var personalizationContext = PersonalizationContext.shared
    @ObservedObject var profileManager = UserProfileManager.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTab: Int = 0
    @State private var showChat = false
    @State private var selectedMood: String? = nil
    
    var body: some View {
        ZStack {
            // Purple gradient background like mockup
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.75, green: 0.70, blue: 0.95),  // Light purple
                    Color(red: 0.85, green: 0.82, blue: 0.98)   // Lighter purple
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Mood Check-in Header (Mockup Style)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            // Profile circle with emoji
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                
                                Text("😊")
                                    .font(.system(size: 30))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("How are you feeling today?")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(personalizationContext.userName.isEmpty ? "User" : personalizationContext.userName + ".")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Mood selector (emoji style from mockup)
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                MoodButton(emoji: "😄", label: "Very\nHappy", isSelected: selectedMood == "very_happy") {
                                    selectedMood = "very_happy"
                                }
                                MoodButton(emoji: "🙂", label: "Happy", isSelected: selectedMood == "happy") {
                                    selectedMood = "happy"
                                }
                                MoodButton(emoji: "😐", label: "Neutral", isSelected: selectedMood == "neutral") {
                                    selectedMood = "neutral"
                                }
                                MoodButton(emoji: "😔", label: "Sad", isSelected: selectedMood == "sad") {
                                    selectedMood = "sad"
                                }
                                MoodButton(emoji: "😢", label: "Very Sad", isSelected: selectedMood == "very_sad") {
                                    selectedMood = "very_sad"
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                    }
                    
                    // MARK: - Main Content (White background)
                    VStack(spacing: 20) {
                        // Today's Check-in Card (Purple card from mockup)
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "figure.mind.and.body")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Check-in")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(getCheckInStatus())
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.55, green: 0.45, blue: 0.85),
                                    Color(red: 0.65, green: 0.55, blue: 0.90)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Personalized Insight Card
                        if let insight = personalizationContext.currentFocus {
                            PersonalizedInsightCard(
                                title: "Your Current Focus",
                                subtitle: insight,
                                description: getInsightDescription(for: insight),
                                icon: "target",
                                color: Color(red: 0.55, green: 0.45, blue: 0.85)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // Stress & Energy Metrics
                        HStack(spacing: 12) {
                            MetricCard(
                                title: "Stress Level",
                                value: personalizationContext.stressLevel,
                                icon: "brain.head.profile",
                                color: Color(red: 0.55, green: 0.45, blue: 0.85),
                                recommendation: getStressRecommendation()
                            )
                            
                            MetricCard(
                                title: "Energy",
                                value: personalizationContext.energyLevel,
                                icon: "bolt.fill",
                                color: Color(red: 0.40, green: 0.70, blue: 0.90),
                                recommendation: getEnergyRecommendation()
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick Actions (Mockup style horizontal buttons)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    QuickActionCard(
                                        icon: "message.fill",
                                        title: "Talk\nto AI",
                                        color: Color(red: 0.55, green: 0.45, blue: 0.85),
                                        action: { showChat = true }
                                    )
                                    
                                    QuickActionCard(
                                        icon: "wind",
                                        title: "Breathing\nExercise",
                                        color: Color(red: 0.40, green: 0.70, blue: 0.90),
                                        action: {}
                                    )
                                    
                                    QuickActionCard(
                                        icon: "book.fill",
                                        title: "Journal\nEntry",
                                        color: Color(red: 0.65, green: 0.55, blue: 0.90),
                                        action: {}
                                    )
                                    
                                    if personalizationContext.greatestNeeds.contains("Fitness") {
                                        QuickActionCard(
                                            icon: "figure.walk",
                                            title: "Activity\nLog",
                                            color: Color(red: 0.50, green: 0.75, blue: 0.70),
                                            action: {}
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Goals Progress
                        if !personalizationContext.primaryGoals.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your Goals")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    ForEach(personalizationContext.primaryGoals.prefix(3), id: \.self) { goal in
                                        GoalCard(
                                            goal: goal,
                                            recommendation: getGoalRecommendation(for: goal)
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Needs-Based Recommendations
                        if !personalizationContext.greatestNeeds.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Personalized for Your Needs")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    ForEach(personalizationContext.greatestNeeds.prefix(2), id: \.self) { need in
                                        NeedCard(
                                            need: need,
                                            context: personalizationContext
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .background(Color.white)
                }
            }
            .sheet(isPresented: $showChat) {
                ChatView_Enhanced(
                    userAnswers: profileManager.currentUserProfile?.userAnswers ?? [:],
                    chatStore: ChatStore()
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCheckInStatus() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Morning mindfulness completed"
        } else if hour < 18 {
            return "Afternoon check-in completed"
        } else {
            return "Evening reflection completed"
        }
    }
    
    private func getInsightDescription(for focus: String) -> String {
        let lower = focus.lowercased()
        if lower.contains("wellness") {
            return "Balance is key - take care of your mind, body, and emotions"
        } else if lower.contains("fitness") {
            return "Movement is medicine - stay active and energized"
        } else if lower.contains("mental") {
            return "Your mental health matters - prioritize self-care"
        } else {
            return "Focus on what matters most to you today"
        }
    }
    
    private func getContextualSubheading() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "You're doing great! Keep up the momentum"
        } else if hour < 18 {
            return "How's your day going so far?"
        } else {
            return "Time to reflect on your day"
        }
    }
    
    private func getStressRecommendation() -> String {
        switch personalizationContext.stressLevel.lowercased() {
        case "low":
            return "Great! Keep maintaining balance"
        case "moderate":
            return "Consider a short walk or stretching"
        case "high":
            return "Try a breathing exercise or meditation"
        default:
            return "Check in with yourself regularly"
        }
    }
    
    private func getEnergyRecommendation() -> String {
        switch personalizationContext.energyLevel.lowercased() {
        case "high":
            return "Perfect time for challenging tasks"
        case "moderate":
            return "Good time for regular activities"
        case "low":
            return "Take it easy and rest when needed"
        default:
            return "Listen to your body's signals"
        }
    }
    
    private func getGoalRecommendation(for goal: String) -> String {
        let lower = goal.lowercased()
        if lower.contains("stress") {
            return "Practice mindfulness or relaxation techniques"
        } else if lower.contains("sleep") {
            return "Establish a consistent bedtime routine"
        } else if lower.contains("fitness") || lower.contains("exercise") {
            return "Start with small, achievable activities"
        } else if lower.contains("nutrition") {
            return "Focus on balanced, nutritious meals"
        } else {
            return "Take one step at a time toward your goal"
        }
    }
}

// MARK: - Mood Button Component
struct MoodButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(getMoodColor().opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    if isSelected {
                        Circle()
                            .stroke(getMoodColor(), lineWidth: 3)
                            .frame(width: 60, height: 60)
                    }
                    
                    Text(emoji)
                        .font(.system(size: 32))
                }
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func getMoodColor() -> Color {
        switch emoji {
        case "😄": return Color(red: 1.0, green: 0.8, blue: 0.4)
        case "🙂": return Color(red: 1.0, green: 0.85, blue: 0.5)
        case "😐": return Color(red: 1.0, green: 0.75, blue: 0.5)
        case "😔": return Color(red: 0.7, green: 0.7, blue: 0.85)
        case "😢": return Color(red: 0.65, green: 0.70, blue: 0.90)
        default: return Color.gray
        }
    }
}

// MARK: - Personalized Insight Card
struct PersonalizedInsightCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .padding(10)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.black.opacity(0.6))
                .lineSpacing(2)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let recommendation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black.opacity(0.5))
                    .textCase(.uppercase)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .textCase(.lowercase)
            
            Text(recommendation)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.black.opacity(0.6))
                .lineLimit(2)
                .lineSpacing(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(width: 180)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color, color.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let goal: String
    let recommendation: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(red: 0.40, green: 0.80, blue: 0.60))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(recommendation)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.black.opacity(0.6))
                    .lineSpacing(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Need Card
struct NeedCard: View {
    let need: String
    let context: PersonalizationContext
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: getIconForNeed(need))
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(getColorForNeed(need))
                .padding(12)
                .background(getColorForNeed(need).opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(need)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                Text(getRecommendationForNeed(need))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.black.opacity(0.6))
                    .lineSpacing(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
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
            return Color(red: 0.40, green: 0.80, blue: 0.60)
        } else if lower.contains("nutrition") || lower.contains("food") {
            return Color(red: 1.0, green: 0.70, blue: 0.40)
        } else if lower.contains("sleep") {
            return Color(red: 0.55, green: 0.45, blue: 0.85)
        } else if lower.contains("stress") || lower.contains("anxiety") {
            return Color(red: 1.0, green: 0.60, blue: 0.60)
        } else if lower.contains("social") || lower.contains("connection") {
            return Color(red: 0.40, green: 0.70, blue: 0.90)
        } else {
            return Color(red: 1.0, green: 0.50, blue: 0.70)
        }
    }
    
    private func getRecommendationForNeed(_ need: String) -> String {
        let lower = need.lowercased()
        if lower.contains("fitness") {
            return "Start with 10 minutes of movement daily"
        } else if lower.contains("nutrition") {
            return "Focus on balanced, whole foods"
        } else if lower.contains("sleep") {
            return "Aim for 7-9 hours of quality sleep"
        } else if lower.contains("stress") {
            return "Try meditation or deep breathing"
        } else if lower.contains("social") {
            return "Reach out to a friend or loved one"
        } else {
            return "Focus on this area that matters to you"
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
