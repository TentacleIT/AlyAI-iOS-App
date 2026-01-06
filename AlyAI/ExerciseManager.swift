import Foundation
import Combine

struct ExerciseResponse: Codable {
    let suggestions: [ExerciseSuggestion]
}

struct ExerciseSuggestion: Codable, Hashable, Identifiable {
    var id = UUID()
    let exerciseName: String
    let description: String
    let duration: String
    let type: String
    let recommendedTime: String
    let iconName: String

    enum CodingKeys: String, CodingKey {
        case exerciseName, description, duration, type, recommendedTime, iconName
    }
}

class ExerciseManager: ObservableObject {
    static let shared = ExerciseManager()
    
    @Published var exerciseSuggestions: [ExerciseSuggestion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        fetchSuggestions()
    }
    
    func fetchSuggestions() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let prompt = buildPrompt()
        
        OpenAIService.shared.runAssessment(prompt: prompt, jsonMode: true) { [weak self] response in
            DispatchQueue.main.async {
                self?.isLoading = false
                do {
                    let data = response.data(using: .utf8)!
                    let response = try JSONDecoder().decode(ExerciseResponse.self, from: data)
                    self?.exerciseSuggestions = response.suggestions
                } catch {
                    self?.errorMessage = "Failed to get exercise suggestions."
                    print("Error decoding exercise suggestions: \(error)")
                }
            }
        }
    }
    
    private func buildPrompt() -> String {
        let userContext = gatherUserContext()
        return """
        You are AlyAI, a wellness-focused AI companion.
        Generate 1-3 short, mentally-supportive PHYSICAL exercise suggestions based on the user's context. Examples include jumping jacks, squats, light cardio, etc.
        
        USER CONTEXT:
        - Mood: \(userContext["mood"] ?? "Stable")
        - Energy Level: \(userContext["energy"] ?? "Moderate")
        - Focus: \(userContext["focus"] ?? "General Wellness")

        INSTRUCTIONS:
        - Exercises must be physical activities. Avoid purely mental exercises like journaling or meditation.
        - Exercises must be safe, low-intensity, and suitable for all users.
        - Tie recommendations to the user’s current focus or mood.
        - Focus on mental relief and wellbeing through physical movement.
        - For iconName, provide a valid SF Symbol name that represents the exercise (e.g., 'figure.walk', 'figure.jumprope').

        OUTPUT FORMAT (STRICT JSON OBJECT):
        {
          "suggestions": [
            {
              "exerciseName": "Mindful Stretch",
              "description": "A 5-minute stretch routine to reduce tension and calm your mind.",
              "duration": "5 mins",
              "type": "mental-health-support",
              "recommendedTime": "morning",
              "iconName": "figure.yoga"
            }
          ]
        }
        """
    }
    
    private func gatherUserContext() -> [String: String] {
        var context: [String: String] = [:]
        if let profile = UserProfileManager.shared.currentUserProfile {
            let answers = profile.userAnswers
            context["focus"] = (answers["main_goal"] as? [String])?.first ?? "General Wellness"
        }
        
        if let log = CycleManager.shared.todayLog {
            context["mood"] = log.mood.state?.rawValue
            context["energy"] = "\(log.energyLevel)/10"
        }
        return context
    }
}
