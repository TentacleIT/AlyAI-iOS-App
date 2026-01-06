import SwiftUI

struct SupportiveExercisesView: View {
    @ObservedObject private var exerciseManager = ExerciseManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supportive Exercises")
                .font(.headline)
            
            if exerciseManager.isLoading {
                ProgressView()
            } else if let errorMessage = exerciseManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(Color.error)
            } else {
                ForEach(exerciseManager.exerciseSuggestions) { suggestion in
                    SupportiveExerciseCard(suggestion: suggestion)
                }
            }
        }
    }
}

struct SupportiveExerciseCard: View {
    let suggestion: ExerciseSuggestion
    
    var body: some View {
        HStack {
            Image(systemName: suggestion.iconName)
                .font(.title)
                .foregroundColor(Color.success)
                .frame(width: 50)
            
            VStack(alignment: .leading) {
                Text(suggestion.exerciseName)
                    .font(.headline)
                Text(suggestion.description)
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                Text("Duration: \(suggestion.duration)")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding()
        .background(Color.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: Color.shadow, radius: 2)
    }
}
