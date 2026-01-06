import SwiftUI

struct NutritionMealsView: View {
    let userAnswers: [String: Any]? 
    
    @ObservedObject private var nutritionManager = NutritionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    init(userAnswers: [String: Any]? = nil) {
        self.userAnswers = userAnswers
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    if nutritionManager.isLoading {
                        loadingState
                    } else if let errorMessage = nutritionManager.errorMessage {
                        errorState(message: errorMessage)
                    } else if let plan = nutritionManager.currentPlan {
                        mealPlanContent(plan: plan)
                    } else {
                        loadingState
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        nutritionManager.refreshPlan()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.accentPrimary)
                    }
                    .disabled(nutritionManager.isLoading)
                }
            }
        }
        .onAppear {
            nutritionManager.loadCachedPlan()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundStyle(Color.success)
            
            Text("Daily Meal Plan")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Nourishment curated for your body & mind today")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.accentPrimary)
            
            Text("Curating your personalized meal plan...")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
            
            Text("Generating images may take a moment.")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(Color.error)
            
            Text("We couldn't generate your plan.")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                nutritionManager.refreshPlan()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.surfacePrimary)
        )
    }
    
    private func mealPlanContent(plan: DailyMealPlan) -> some View {
        VStack(spacing: 24) {
            
            // Progress Note
            if let note = plan.progressNote, !note.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(Color.accentPrimary)
                    Text(note)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfacePrimary)
                )
            }
            
            MealDetailCard(type: "Breakfast", meal: plan.meals.breakfast)
            MealDetailCard(type: "Lunch", meal: plan.meals.lunch)
            MealDetailCard(type: "Dinner", meal: plan.meals.dinner)
        }
    }
}

struct MealDetailCard: View {
    let type: String
    let meal: MealDetail
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                if let urlString = meal.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.textSecondary.opacity(0.1))
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.textSecondary.opacity(0.1))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(Color.textSecondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 220)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(Color.textSecondary.opacity(0.1))
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(Color.textSecondary)
                        )
                }
                
                // Meal Type Badge
                Text(type.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.backgroundPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.textPrimary.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                
                Text(meal.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                
                Text(meal.whyItHelps)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(Color.textSecondary)
                
                if isExpanded {
                    Divider()
                    
                    Text("About this meal")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textSecondary)
                        .textCase(.uppercase)
                    
                    Text(meal.description)
                        .font(.body)
                        .foregroundColor(Color.textPrimary)
                        .lineSpacing(4)
                    
                    Divider().padding(.vertical, 4)
                    
                    Text("How to Prepare")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textSecondary)
                        .textCase(.uppercase)
                    
                    Text(meal.howToPrepare)
                        .font(.body)
                        .foregroundColor(Color.textPrimary)
                        .lineSpacing(4)
                }
                
                // Expand/Collapse Indicator
                HStack {
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color.accentPrimary)
                        .padding(.top, 4)
                    Spacer()
                }
            }
            .padding()
            .background(Color.surfacePrimary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.shadow, radius: 10, x: 0, y: 5)
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    NutritionMealsView()
}
