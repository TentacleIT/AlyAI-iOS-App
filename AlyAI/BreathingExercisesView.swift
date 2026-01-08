import SwiftUI

struct BreathingExercisesView: View {
    let userAnswers: [String: Any]
    @State private var selectedExercise: BreathingExercise?
    @State private var isBreathing = false
    @State private var breathCount = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "lungs.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.blue)
                        
                        Text("Breathing Exercises")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Calm your mind and body with guided breathing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Breathing Exercises
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose a Technique")
                            .font(.headline)
                        
                        ForEach(getBreathingExercises()) { exercise in
                            BreathingExerciseCard(exercise: exercise) {
                                selectedExercise = exercise
                            }
                        }
                    }
                    
                    // Quick Tips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Breathing Tips")
                            .font(.headline)
                        
                        BreathingTipCard(icon: "hand.raised.fill", title: "Find a Quiet Space", description: "Choose a comfortable, distraction-free area", color: .blue)
                        BreathingTipCard(icon: "figure.seated.side", title: "Sit Comfortably", description: "Keep your spine straight and shoulders relaxed", color: .green)
                        BreathingTipCard(icon: "clock.fill", title: "Practice Daily", description: "Even 5 minutes a day can make a difference", color: .orange)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
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
        .sheet(item: $selectedExercise) { exercise in
            AnimatedBreathingGuideView(technique: mapExerciseToTechnique(exercise))
        }
    }
    
    private func mapExerciseToTechnique(_ exercise: BreathingExercise) -> BreathingTechnique {
        switch exercise.title {
        case "Box Breathing":
            return .boxBreathing
        case "4-7-8 Breathing":
            return .breathing478
        case "Deep Belly Breathing":
            return .deepBelly
        case "Alternate Nostril":
            return .alternateNostril
        default:
            return .boxBreathing
        }
    }
    
    private func getBreathingExercises() -> [BreathingExercise] {
        return [
            BreathingExercise(
                title: "Box Breathing",
                duration: 5,
                description: "Equal counts for inhale, hold, exhale, hold",
                icon: "square",
                pattern: "Inhale 4 → Hold 4 → Exhale 4 → Hold 4",
                benefits: ["Reduces stress", "Improves focus", "Calms nervous system"]
            ),
            BreathingExercise(
                title: "4-7-8 Breathing",
                duration: 5,
                description: "Natural tranquilizer for the nervous system",
                icon: "moon.stars.fill",
                pattern: "Inhale 4 → Hold 7 → Exhale 8",
                benefits: ["Promotes sleep", "Reduces anxiety", "Lowers blood pressure"]
            ),
            BreathingExercise(
                title: "Deep Belly Breathing",
                duration: 5,
                description: "Diaphragmatic breathing for relaxation",
                icon: "figure.mind.and.body",
                pattern: "Breathe deeply into belly → Slow exhale",
                benefits: ["Reduces tension", "Increases oxygen", "Grounds you"]
            ),
            BreathingExercise(
                title: "Alternate Nostril",
                duration: 5,
                description: "Balance your energy and calm your mind",
                icon: "wind",
                pattern: "Breathe through one nostril at a time",
                benefits: ["Balances energy", "Clears mind", "Reduces stress"]
            )
        ]
    }
}

struct BreathingExercise: Identifiable {
    let id = UUID()
    let title: String
    let duration: Int
    let description: String
    let icon: String
    let pattern: String
    let benefits: [String]
}

struct BreathingExerciseCard: View {
    let exercise: BreathingExercise
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 16) {
                Image(systemName: exercise.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(exercise.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(exercise.duration) min")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: Color(uiColor: .label).opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct BreathingSessionView: View {
    let exercise: BreathingExercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: exercise.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    Text(exercise.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Pattern
                    VStack(spacing: 16) {
                        Text("Breathing Pattern")
                            .font(.headline)
                        
                        Text(exercise.pattern)
                            .font(.title3)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .padding()
                    
                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.headline)
                        
                        ForEach(exercise.benefits, id: \.self) { benefit in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(benefit)
                                    .font(.body)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )
                    .padding(.horizontal)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Practice")
                            .font(.headline)
                        
                        Text("1. Find a comfortable seated position")
                        Text("2. Close your eyes or soften your gaze")
                        Text("3. Follow the breathing pattern above")
                        Text("4. Practice for \(exercise.duration) minutes")
                        Text("5. End with a few natural breaths")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BreathingTipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

#Preview {
    BreathingExercisesView(userAnswers: [:])
}
