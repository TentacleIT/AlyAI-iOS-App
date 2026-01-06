import SwiftUI

struct SleepRecoveryView: View {
    let userAnswers: [String: Any]
    @State private var sleepHours: Double = 7.5
    @State private var sleepQuality: Int = 3
    @State private var bedtimeRoutines: [BedtimeRoutine] = []
    @State private var completedRoutines: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.indigo)
                        
                        Text("Sleep & Recovery")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Optimize your rest for better energy and wellness")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Sleep Summary Card
                    sleepSummaryCard
                    
                    // Sleep Quality Tracker
                    sleepQualityCard
                    
                    // Bedtime Routine Checklist
                    bedtimeRoutineSection
                    
                    // Sleep Tips
                    sleepTipsSection
                    
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
        .onAppear {
            loadBedtimeRoutines()
        }
    }
    
    private var sleepSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Night")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(sleepHours, specifier: "%.1f") hours")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: sleepHours / 8.0)
                        .stroke(Color.indigo, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int((sleepHours / 8.0) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("of 8hr")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 70, height: 70)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                sleepMetric(icon: "bed.double.fill", label: "Bedtime", value: "10:30 PM", color: .indigo)
                sleepMetric(icon: "sunrise.fill", label: "Wake Up", value: "6:00 AM", color: .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.indigo.opacity(0.1))
        )
    }
    
    private var sleepQualityCard: some View {
        VStack(spacing: 16) {
            Text("How did you sleep last night?")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        sleepQuality = rating
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: rating <= sleepQuality ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(rating <= sleepQuality ? .yellow : .gray)
                            
                            if rating == 1 {
                                Text("Poor")
                                    .font(.caption2)
                            } else if rating == 5 {
                                Text("Great")
                                    .font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
    
    private var bedtimeRoutineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tonight's Bedtime Routine")
                .font(.headline)
            
            ForEach(bedtimeRoutines) { routine in
                BedtimeRoutineRow(
                    routine: routine,
                    isCompleted: completedRoutines.contains(routine.id)
                ) {
                    if completedRoutines.contains(routine.id) {
                        completedRoutines.remove(routine.id)
                    } else {
                        completedRoutines.insert(routine.id)
                    }
                }
            }
        }
    }
    
    private var sleepTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Better Sleep Tips")
                .font(.headline)
            
            SleepTipCard(icon: "lightbulb.slash.fill", title: "Dim the Lights", description: "Reduce blue light 1-2 hours before bed", color: .indigo)
            SleepTipCard(icon: "thermometer.medium", title: "Cool Room", description: "Keep bedroom at 65-68°F for optimal sleep", color: .blue)
            SleepTipCard(icon: "cup.and.saucer.fill", title: "Limit Caffeine", description: "Avoid caffeine after 2 PM", color: .brown)
            SleepTipCard(icon: "clock.badge.checkmark", title: "Consistent Schedule", description: "Go to bed and wake up at the same time", color: .green)
        }
    }
    
    private func sleepMetric(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func loadBedtimeRoutines() {
        bedtimeRoutines = [
            BedtimeRoutine(title: "Dim the lights", time: "9:00 PM", icon: "lightbulb.slash.fill"),
            BedtimeRoutine(title: "Stop screen time", time: "9:30 PM", icon: "iphone.slash"),
            BedtimeRoutine(title: "Light stretching", time: "9:45 PM", icon: "figure.flexibility"),
            BedtimeRoutine(title: "Reading or journaling", time: "10:00 PM", icon: "book.fill"),
            BedtimeRoutine(title: "Meditation or breathing", time: "10:15 PM", icon: "sparkles"),
            BedtimeRoutine(title: "In bed by", time: "10:30 PM", icon: "bed.double.fill")
        ]
    }
}

struct BedtimeRoutine: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let icon: String
}

struct BedtimeRoutineRow: View {
    let routine: BedtimeRoutine
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? .indigo : .gray)
                
                Image(systemName: routine.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.indigo)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(routine.time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color.indigo.opacity(0.1) : Color(.systemGray6))
            )
        }
    }
}

struct SleepTipCard: View {
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
    SleepRecoveryView(userAnswers: [:])
}
