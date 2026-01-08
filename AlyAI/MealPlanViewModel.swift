import Foundation
import SwiftUI

/// ViewModel for managing meal plan generation and state
@MainActor
class MealPlanViewModel: ObservableObject {
    @Published var mealPlan: DailyMealPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let personalizationContext = PersonalizationContext.shared
    private let openAIService = OpenAIService.shared
    
    /// Generate a new meal plan based on user profile
    func generateMealPlan() {
        isLoading = true
        errorMessage = nil
        
        let prompt = buildMealPlanPrompt()
        
        print("🍽️ [MealPlanViewModel] Generating meal plan...")
        print("📍 Location: \(personalizationContext.country)")
        print("🎯 Goals: \(personalizationContext.primaryGoals.joined(separator: ", "))")
        
        openAIService.runAssessment(prompt: prompt, jsonMode: true) { [weak self] response in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isLoading = false
                
                if response.hasPrefix("Error:") {
                    self.errorMessage = "Failed to generate meal plan. Please try again."
                    print("❌ [MealPlanViewModel] Error: \(response)")
                    return
                }
                
                // Parse JSON response
                guard let data = response.data(using: .utf8) else {
                    self.errorMessage = "Failed to process meal plan data."
                    print("❌ [MealPlanViewModel] Failed to convert response to data")
                    return
                }
                
                do {
                    let mealPlanResponse = try JSONDecoder().decode(MealPlanResponse.self, from: data)
                    self.mealPlan = self.convertToMealPlan(mealPlanResponse)
                    print("✅ [MealPlanViewModel] Meal plan generated successfully with \(self.mealPlan?.meals.count ?? 0) meals")
                } catch {
                    self.errorMessage = "Failed to parse meal plan. Please try again."
                    print("❌ [MealPlanViewModel] Parse error: \(error)")
                    print("📄 Response: \(response)")
                }
            }
        }
    }
    
    /// Regenerate meal plan (clears current plan and generates new one)
    func regenerateMealPlan() {
        mealPlan = nil
        generateMealPlan()
    }
    
    // MARK: - Private Methods
    
    /// Build personalized prompt for OpenAI
    private func buildMealPlanPrompt() -> String {
        let age = personalizationContext.userAge
        let gender = personalizationContext.gender.isEmpty ? "not specified" : personalizationContext.gender
        let goals = personalizationContext.primaryGoals.isEmpty ? ["general wellness"] : personalizationContext.primaryGoals
        let needs = personalizationContext.greatestNeeds.isEmpty ? ["balanced nutrition"] : personalizationContext.greatestNeeds
        let dietary = personalizationContext.dietaryPreferences.isEmpty ? ["no restrictions"] : personalizationContext.dietaryPreferences
        let allergies = personalizationContext.allergies.isEmpty ? "none" : personalizationContext.allergies.joined(separator: ", ")
        let country = personalizationContext.country.isEmpty ? "Global" : personalizationContext.country
        
        // Determine calorie target based on goals
        let calorieTarget = determineCalorieTarget(age: age, gender: gender, goals: goals)
        
        return """
        You are a professional nutritionist and meal planner. Create a personalized daily meal plan for today.
        
        USER PROFILE:
        - Age: \(age)
        - Gender: \(gender)
        - Location/Country: \(country)
        - Health Goals: \(goals.joined(separator: ", "))
        - Greatest Needs: \(needs.joined(separator: ", "))
        - Dietary Preferences: \(dietary.joined(separator: ", "))
        - Allergies: \(allergies)
        - Target Daily Calories: ~\(calorieTarget) kcal
        
        REQUIREMENTS:
        1. Create meals that are culturally appropriate for \(country)
        2. If in Nigeria, use Nigerian/West African foods (e.g., Jollof Rice, Egusi Soup, Moi Moi, Plantain, etc.)
        3. If elsewhere, use foods common and available in that region
        4. Respect all dietary preferences and allergies
        5. Align with health goals (weight loss, muscle gain, wellness, etc.)
        6. Provide realistic, achievable meals
        7. Include breakfast, lunch, dinner, and optionally 1 snack
        8. Calculate accurate calories and macronutrients
        
        OUTPUT FORMAT (JSON):
        {
          "meals": [
            {
              "type": "breakfast" | "lunch" | "dinner" | "snack",
              "name": "Meal Name",
              "description": "Brief description (1-2 sentences)",
              "ingredients": ["ingredient 1", "ingredient 2", ...],
              "preparation_steps": ["step 1", "step 2", ...],
              "calories": 450,
              "protein": 25,
              "carbs": 50,
              "fats": 15
            }
          ]
        }
        
        Make it delicious, practical, and culturally relevant!
        """
    }
    
    /// Determine appropriate calorie target based on user profile
    private func determineCalorieTarget(age: Int, gender: String, goals: [String]) -> Int {
        // Base metabolic rate estimation
        var baseCalories = 2000
        
        // Adjust for gender
        if gender.lowercased() == "male" {
            baseCalories = 2400
        } else if gender.lowercased() == "female" {
            baseCalories = 1800
        }
        
        // Adjust for age
        if age < 25 {
            baseCalories += 200
        } else if age > 50 {
            baseCalories -= 200
        }
        
        // Adjust for goals
        let goalsLower = goals.map { $0.lowercased() }
        if goalsLower.contains(where: { $0.contains("weight loss") || $0.contains("lose weight") }) {
            baseCalories -= 300
        } else if goalsLower.contains(where: { $0.contains("muscle") || $0.contains("gain weight") || $0.contains("bulk") }) {
            baseCalories += 400
        }
        
        return max(1200, min(3000, baseCalories)) // Keep within reasonable range
    }
    
    /// Convert API response to DailyMealPlan model
    private func convertToMealPlan(_ response: MealPlanResponse) -> DailyMealPlan {
        let meals = response.meals.compactMap { mealResponse -> Meal? in
            guard let mealType = MealType(rawValue: mealResponse.type.capitalized) else {
                return nil
            }
            
            return Meal(
                type: mealType,
                name: mealResponse.name,
                description: mealResponse.description,
                ingredients: mealResponse.ingredients,
                preparationSteps: mealResponse.preparation_steps,
                calories: mealResponse.calories,
                macronutrients: Macronutrients(
                    protein: mealResponse.protein,
                    carbs: mealResponse.carbs,
                    fats: mealResponse.fats
                )
            )
        }
        
        return DailyMealPlan(date: Date(), meals: meals)
    }
}
