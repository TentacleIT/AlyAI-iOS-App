import SwiftUI

struct MealPlanItem: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let ingredients: [String]
    let prepTime: String
}

struct FeatureContent: Codable {
    let category: String
    let goal: String
    let introduction: String
    let actions: [String]
    let tips: [String]
}

struct SupportFeatureDetailView: View {
    let feature: SupportPlanItem
    let userAnswers: [String: Any]
    
    @State private var isLoading = true
    @State private var featureContent: FeatureContent?
    @State private var mealPlan: [MealPlanItem] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // Route to specialized views based on feature type
        switch feature.title {
        case "Nutrition & Meals", "Personalized Nutrition":
            NutritionMealsView(userAnswers: userAnswers)
        case "Water Intake":
            WaterIntakeView(userAnswers: userAnswers)
        case "Medical Companion":
            MedicalCompanionView(userAnswers: userAnswers)
        case "Movement & Energy", "Adaptive Movement":
            MovementEnergyView(userAnswers: userAnswers)
        case "Mind & Emotions":
            MindEmotionsView(userAnswers: userAnswers)
        case "Mood Tracking":
            MindEmotionsView(userAnswers: userAnswers, title: "Mood Tracking")
        case "Daily Meditation":
            DailyMeditationView(userAnswers: userAnswers)
        case "Mindfulness Practice":
            DailyMeditationView(userAnswers: userAnswers, title: "Mindfulness Practice")
        case "Sleep & Recovery":
            SleepRecoveryView(userAnswers: userAnswers)
        case "Energy Optimization":
            EnergyOptimizationView(userAnswers: userAnswers)
        case "Sunlight Exposure":
            EnergyOptimizationView(userAnswers: userAnswers, title: "Sunlight Exposure")
        case "Breathing Exercises":
            BreathingExercisesView(userAnswers: userAnswers)
        case "Stress Management":
            MindEmotionsView(userAnswers: userAnswers, title: "Stress Management")
        default:
            defaultFeatureView
        }
    }
    
    private var defaultFeatureView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    if let content = featureContent {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 60))
                                .foregroundStyle(Color.alyaiGradient)
                            
                            Text(feature.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text(content.category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.alyaiPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.alyaiLightPurple.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                if let related = feature.relatedNeeds, !related.isEmpty {
                                    Text("For: " + related.prefix(1).first!)
                                       .font(.subheadline)
                                       .fontWeight(.medium)
                                       .foregroundColor(.alyaiEmotional)
                                       .padding(.horizontal, 12)
                                       .padding(.vertical, 6)
                                       .background(Color.alyaiLightPurple.opacity(0.2))
                                       .clipShape(Capsule())
                                }
                            }
                            
                            Text(content.introduction)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Goal Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Goal")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(content.goal)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)
                        
                        // Progress Indicator (Placeholder for now)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Daily Progress")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("0%")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.alyaiPrimary)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(Color.alyaiGradient)
                                        .frame(width: 0, height: 8) // 0% width for now
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(.horizontal)
                        
                        // Action Items
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Actions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(Array(content.actions.enumerated()), id: \.offset) { index, item in
                                HStack(alignment: .top, spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.alyaiLightPurple.opacity(0.3))
                                            .frame(width: 32, height: 32)
                                        
                                        Text("\(index + 1)")
                                            .font(.headline)
                                            .foregroundColor(.alyaiPrimary)
                                    }
                                    
                                    Text(item)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .padding(.top, 4)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // Tips
                        if !content.tips.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Helpful Tips")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(content.tips, id: \.self) { tip in
                                    HStack(spacing: 12) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                        Text(tip)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        // Call to Action
                        Button {
                            // Action to start or log
                        } label: {
                            Text("Start Session")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.alyaiPrimary)
                                        .shadow(color: .alyaiPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                    } else {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.alyaiPrimary)
                                .scaleEffect(1.2)
                            Text("Creating your personalized plan...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.alyaiPrimary)
                    }
                }
            }
        }
        .onAppear {
            generatePersonalizedContent()
        }
    }
    
    private func generatePersonalizedContent() {
        // Map Onboarding keys to profile
        let goals = (userAnswers["main_goal"] as? [String])?.joined(separator: ", ") ?? (userAnswers["main_goal"] as? String) ?? "General Wellness"
        
        var need: String
        if let nArray = userAnswers["greatest_need"] as? [String] {
             need = nArray.joined(separator: ", ")
        } else if let nString = userAnswers["greatest_need"] as? String {
             need = nString
        } else {
             need = "Support"
        }
        
        let achievement = userAnswers["achievement"] as? String ?? "Balance"
        let bodyConnection = userAnswers["body_connection"] as? Int ?? 5
        
        // Context from Assessment
        let featureContext = feature.description != nil ? "This feature was recommended because: \(feature.description!)" : ""
        let relatedContext = feature.relatedNeeds != nil ? "It specifically addresses these user needs: \(feature.relatedNeeds!.joined(separator: ", "))" : ""
        
        let prompt = """
        You are AlyAI, a compassionate AI life companion.
        
        Generate a JSON object for the "\(feature.title)" feature based on the user's profile.
        
        USER'S PROFILE:
        - Goals: \(goals)
        - Primary Needs: \(need)
        - Desired Achievement: \(achievement)
        - Body Connection: \(bodyConnection)/10
        
        CONTEXT:
        \(featureContext)
        \(relatedContext)
        
        REQUIREMENTS:
        1. "category": A short category (e.g., "Emotional Wellness", "Physical Health").
        2. "goal": A specific, achievable goal for this feature (e.g., "Reduce daily stress by 10%").
        3. "introduction": A warm, 2-sentence explanation of why this feature helps them specifically.
        4. "actions": A list of 3-5 specific, actionable steps tailored to their energy level.
        5. "tips": A list of 2 helpful tips to succeed.
        
        Respond with ONLY the valid JSON object. Do not include markdown formatting like ```json.
        Example format:
        {
          "category": "Mindfulness",
          "goal": "Practice daily grounding",
          "introduction": "This helps you...",
          "actions": ["Step 1", "Step 2"],
          "tips": ["Tip 1", "Tip 2"]
        }
        """
        
        OpenAIService.shared.runAssessment(prompt: prompt) { response in
            DispatchQueue.main.async {
                if let data = response.data(using: .utf8),
                   let content = try? JSONDecoder().decode(FeatureContent.self, from: data) {
                    self.featureContent = content
                    self.isLoading = false
                } else {
                    // Fallback manual parsing if JSON fails (simple version or just retry)
                    // For now we set loading to false but keep content nil to show retry or error
                    // In a real app we'd have error handling.
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    SupportFeatureDetailView(
        feature: SupportPlanItem(title: "Daily Meditation", icon: "brain.head.profile"),
        userAnswers: ["current_focus": "Managing stress or anxiety"]
    )
}
