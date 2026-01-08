import Foundation
import SwiftUI

// MARK: - Meal Plan Models

/// Represents a single meal with all nutritional and preparation details
struct Meal: Identifiable, Codable {
    let id: UUID
    let type: MealType
    let name: String
    let description: String
    let ingredients: [String]
    let preparationSteps: [String]
    let calories: Int
    let macronutrients: Macronutrients
    var imageURL: String?
    
    init(id: UUID = UUID(), type: MealType, name: String, description: String, ingredients: [String], preparationSteps: [String], calories: Int, macronutrients: Macronutrients, imageURL: String? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.ingredients = ingredients
        self.preparationSteps = preparationSteps
        self.calories = calories
        self.macronutrients = macronutrients
        self.imageURL = imageURL
    }
}

/// Types of meals in a day
enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return Color(red: 1.0, green: 0.8, blue: 0.4)
        case .lunch: return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .dinner: return Color(red: 0.55, green: 0.45, blue: 0.85)
        case .snack: return Color(red: 0.50, green: 0.75, blue: 0.70)
        }
    }
}

/// Macronutrient breakdown
struct Macronutrients: Codable {
    let protein: Int  // grams
    let carbs: Int    // grams
    let fats: Int     // grams
    
    var description: String {
        "P: \(protein)g • C: \(carbs)g • F: \(fats)g"
    }
}

/// Complete daily meal plan
struct DailyMealPlan: Identifiable, Codable {
    let id: UUID
    let date: Date
    let meals: [Meal]
    let totalCalories: Int
    let totalMacronutrients: Macronutrients
    
    init(id: UUID = UUID(), date: Date, meals: [Meal]) {
        self.id = id
        self.date = date
        self.meals = meals
        self.totalCalories = meals.reduce(0) { $0 + $1.calories }
        self.totalMacronutrients = Macronutrients(
            protein: meals.reduce(0) { $0 + $1.macronutrients.protein },
            carbs: meals.reduce(0) { $0 + $1.macronutrients.carbs },
            fats: meals.reduce(0) { $0 + $1.macronutrients.fats }
        )
    }
}

/// Response structure from OpenAI for meal plan generation
struct MealPlanResponse: Codable {
    let meals: [MealResponse]
}

struct MealResponse: Codable {
    let type: String
    let name: String
    let description: String
    let ingredients: [String]
    let preparation_steps: [String]
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
}
