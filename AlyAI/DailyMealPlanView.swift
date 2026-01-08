import SwiftUI

struct DailyMealPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = MealPlanViewModel()
    @ObservedObject private var personalizationContext = PersonalizationContext.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.55, green: 0.45, blue: 0.85),
                        Color(red: 0.65, green: 0.55, blue: 0.90)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let mealPlan = viewModel.mealPlan {
                    mealPlanContent(mealPlan)
                }
            }
            .navigationTitle("Today's Meal Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.regenerateMealPlan() }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title3)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                if viewModel.mealPlan == nil {
                    viewModel.generateMealPlan()
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Creating your personalized meal plan...")
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Considering your goals, preferences, and location")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Oops!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(error)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { viewModel.generateMealPlan() }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.85))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }
    
    // MARK: - Meal Plan Content
    
    private func mealPlanContent(_ mealPlan: DailyMealPlan) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Calories")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\(mealPlan.totalCalories) kcal")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Macros")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text(mealPlan.totalMacronutrients.description)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    if !personalizationContext.country.isEmpty && personalizationContext.country != "Global" {
                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text("Meals tailored for \(personalizationContext.country)")
                                .font(.caption)
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.2))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Meal Cards
                ForEach(mealPlan.meals) { meal in
                    MealCardView(meal: meal)
                        .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Meal Card View

struct MealCardView: View {
    let meal: Meal
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(meal.type.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        Image(systemName: meal.type.icon)
                            .font(.title3)
                            .foregroundColor(meal.type.color)
                    }
                    
                    // Meal Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.type.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black.opacity(0.6))
                        Text(meal.name)
                            .font(.headline)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Calories
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(meal.calories)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("kcal")
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    
                    // Expand Icon
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(meal.type.color)
                        .font(.title3)
                }
                .padding(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    // Description
                    Text(meal.description)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                    
                    // Macros
                    HStack(spacing: 16) {
                        MacroLabel(title: "Protein", value: "\(meal.macronutrients.protein)g", color: .red)
                        MacroLabel(title: "Carbs", value: "\(meal.macronutrients.carbs)g", color: .orange)
                        MacroLabel(title: "Fats", value: "\(meal.macronutrients.fats)g", color: .yellow)
                    }
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(meal.type.color)
                            Text("Ingredients")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        
                        ForEach(meal.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(meal.type.color)
                                Text(ingredient)
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                    }
                    
                    // Preparation Steps
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(meal.type.color)
                            Text("How to Prepare")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                        
                        ForEach(Array(meal.preparationSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(meal.type.color)
                                Text(step)
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.8))
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Macro Label

struct MacroLabel: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(title)
                .font(.caption2)
                .foregroundColor(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct DailyMealPlanView_Previews: PreviewProvider {
    static var previews: some View {
        DailyMealPlanView()
    }
}
