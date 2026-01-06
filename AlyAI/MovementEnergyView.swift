import SwiftUI

struct MovementEnergyView: View {
    let userAnswers: [String: Any]
    @State private var selectedCategory: ExerciseCategory = .stretching
    @State private var completedExercises: Set<UUID> = []
    @State private var dailyGoal: Int = 30 // minutes
    @State private var minutesCompleted: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.alyaiPhysical)
                        
                        Text("Movement & Energy")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Gentle movement routines designed for your energy level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Progress Card
                    activityProgressCard
                    
                    // Category Selector
                    categorySelector
                    
                    // Exercise Routines
                    exerciseRoutinesSection
                    
                    // Energy Boost Tips
                    energyTipsSection
                    
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
    }
    
    private var activityProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(minutesCompleted)/\(dailyGoal) min")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.alyaiPhysical)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: Double(minutesCompleted) / Double(dailyGoal))
                        .stroke(Color.alyaiPhysical, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int((Double(minutesCompleted) / Double(dailyGoal)) * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(width: 60, height: 60)
            }
            
            ProgressView(value: Double(minutesCompleted), total: Double(dailyGoal))
                .tint(.alyaiPhysical)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.alyaiLightGreen.opacity(0.2))
        )
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryButton(category: .stretching, isSelected: selectedCategory == .stretching) {
                    selectedCategory = .stretching
                }
                CategoryButton(category: .walking, isSelected: selectedCategory == .walking) {
                    selectedCategory = .walking
                }
                CategoryButton(category: .yoga, isSelected: selectedCategory == .yoga) {
                    selectedCategory = .yoga
                }
                CategoryButton(category: .breathing, isSelected: selectedCategory == .breathing) {
                    selectedCategory = .breathing
                }
            }
        }
    }
    
    private var exerciseRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedCategory.title)
                .font(.headline)
            
            ForEach(getExercises(for: selectedCategory)) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    isCompleted: completedExercises.contains(exercise.id)
                ) {
                    if completedExercises.contains(exercise.id) {
                        completedExercises.remove(exercise.id)
                        minutesCompleted -= exercise.duration
                    } else {
                        completedExercises.insert(exercise.id)
                        minutesCompleted += exercise.duration
                    }
                }
            }
        }
    }
    
    private var energyTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Energy Boost Tips")
                .font(.headline)
            
            TipCard(icon: "sun.max.fill", title: "Morning Sunlight", description: "Get 10-15 minutes of natural light", color: .orange)
            TipCard(icon: "figure.walk.motion", title: "Movement Breaks", description: "Stand and stretch every hour", color: .green)
            TipCard(icon: "leaf.fill", title: "Stay Nourished", description: "Eat balanced meals throughout the day", color: .alyaiPhysical)
        }
    }
    
    private func getExercises(for category: ExerciseCategory) -> [Exercise] {
        switch category {
        case .stretching:
            return [
                Exercise(title: "Neck & Shoulder Release", duration: 5, difficulty: .easy, steps: ["Gently tilt head side to side", "Roll shoulders backward 5 times", "Hold each stretch for 30 seconds"]),
                Exercise(title: "Full Body Stretch", duration: 10, difficulty: .easy, steps: ["Reach arms overhead", "Bend forward gently", "Stretch sides and back"]),
                Exercise(title: "Seated Stretches", duration: 5, difficulty: .easy, steps: ["Twist torso left and right", "Stretch arms across body", "Ankle circles"])
            ]
        case .walking:
            return [
                Exercise(title: "Gentle Morning Walk", duration: 15, difficulty: .easy, steps: ["Start with slow pace", "Focus on breathing", "Enjoy surroundings"]),
                Exercise(title: "Brisk Walk", duration: 20, difficulty: .medium, steps: ["Warm up for 5 minutes", "Increase pace gradually", "Cool down at the end"])
            ]
        case .yoga:
            return [
                Exercise(title: "Morning Flow", duration: 10, difficulty: .easy, steps: ["Cat-cow stretches", "Downward dog", "Child's pose"]),
                Exercise(title: "Restorative Poses", duration: 15, difficulty: .easy, steps: ["Legs up the wall", "Supported backbend", "Savasana"])
            ]
        case .breathing:
            return [
                Exercise(title: "Box Breathing", duration: 5, difficulty: .easy, steps: ["Inhale for 4 counts", "Hold for 4 counts", "Exhale for 4 counts", "Hold for 4 counts"]),
                Exercise(title: "Deep Belly Breathing", duration: 5, difficulty: .easy, steps: ["Place hand on belly", "Breathe deeply into belly", "Feel belly rise and fall"])
            ]
        }
    }
}

// MARK: - Models

enum ExerciseCategory: CaseIterable {
    case stretching, walking, yoga, breathing
    
    var title: String {
        switch self {
        case .stretching: return "Stretching Routines"
        case .walking: return "Walking Plans"
        case .yoga: return "Yoga Flows"
        case .breathing: return "Breathing Exercises"
        }
    }
    
    var icon: String {
        switch self {
        case .stretching: return "figure.flexibility"
        case .walking: return "figure.walk"
        case .yoga: return "figure.mind.and.body"
        case .breathing: return "lungs.fill"
        }
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let title: String
    let duration: Int // minutes
    let difficulty: Difficulty
    let steps: [String]
    
    enum Difficulty {
        case easy, medium, hard
        
        var text: String {
            switch self {
            case .easy: return "Easy"
            case .medium: return "Medium"
            case .hard: return "Hard"
            }
        }
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: category.icon)
                Text(category.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? AnyShapeStyle(Color.alyaiGradient) : AnyShapeStyle(Color(.systemGray6)))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let isCompleted: Bool
    let onToggle: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        HStack {
                            Text("\(exercise.duration) min")
                                .font(.caption)
                            Text("•")
                                .font(.caption)
                            Text(exercise.difficulty.text)
                                .font(.caption)
                                .foregroundColor(exercise.difficulty.color)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        onToggle()
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundColor(isCompleted ? .alyaiPhysical : .gray)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to do it:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.alyaiPhysical)
                            Text(step)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isCompleted ? Color.alyaiLightGreen.opacity(0.2) : Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct TipCard: View {
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
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    MovementEnergyView(userAnswers: [:])
}
