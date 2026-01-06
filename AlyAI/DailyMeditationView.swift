import SwiftUI

struct DailyMeditationView: View {
    let userAnswers: [String: Any]
    var title: String = "Daily Meditation"
    @State private var meditationSessions: [MeditationSession] = []
    @State private var selectedSession: MeditationSession?
    @State private var meditationStreak: Int = 3
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.purple)
                        
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Cultivate mindfulness and inner peace through meditation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Meditation Streak
                    meditationStreakCard
                    
                    // Meditation Sessions
                    meditationSessionsSection
                    
                    // Meditation Tips
                    meditationTipsSection
                    
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
            loadMeditationSessions()
        }
        .sheet(item: $selectedSession) { session in
            MeditationSessionDetailView(session: session)
        }
    }
    
    private var meditationStreakCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meditation Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(meditationStreak) days")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    Circle()
                        .fill(day < meditationStreak ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(getDayLabel(day))
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    private var meditationSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Guided Meditations")
                .font(.headline)
            
            ForEach(meditationSessions) { session in
                MeditationSessionCard(session: session) {
                    selectedSession = session
                }
            }
        }
    }
    
    private var meditationTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meditation Tips")
                .font(.headline)
            
            MeditationTipCard(icon: "clock", title: "Same Time Daily", description: "Meditate at the same time each day to build habit", color: .purple)
            MeditationTipCard(icon: "location.fill", title: "Quiet Space", description: "Find a comfortable, distraction-free area", color: .blue)
            MeditationTipCard(icon: "figure.seated.side", title: "Comfortable Position", description: "Sit in a way that feels natural and relaxed", color: .green)
            MeditationTipCard(icon: "heart.fill", title: "Be Patient", description: "It's normal for your mind to wander - gently return focus", color: .red)
        }
    }
    
    private func getDayLabel(_ day: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[day]
    }
    
    private func loadMeditationSessions() {
        meditationSessions = [
            MeditationSession(
                title: "Morning Mindfulness",
                duration: 10,
                description: "Start your day with clarity and calm",
                icon: "sunrise.fill",
                type: "Mindfulness",
                steps: [
                    "Find a comfortable seated position",
                    "Close your eyes gently",
                    "Focus on your breath",
                    "Notice thoughts without judgment",
                    "Return focus to breath when mind wanders"
                ]
            ),
            MeditationSession(
                title: "Body Scan",
                duration: 15,
                description: "Release tension and connect with your body",
                icon: "figure.mind.and.body",
                type: "Body Awareness",
                steps: [
                    "Lie down or sit comfortably",
                    "Start at your toes",
                    "Slowly scan up through your body",
                    "Notice any sensations",
                    "Breathe into areas of tension"
                ]
            ),
            MeditationSession(
                title: "Loving-Kindness",
                duration: 15,
                description: "Cultivate compassion for yourself and others",
                icon: "heart.circle.fill",
                type: "Compassion",
                steps: [
                    "Sit comfortably with eyes closed",
                    "Think of someone you love",
                    "Repeat: 'May you be happy, may you be healthy'",
                    "Direct these wishes to yourself",
                    "Extend to all beings"
                ]
            ),
            MeditationSession(
                title: "Breath Awareness",
                duration: 5,
                description: "Quick centering practice for any time",
                icon: "wind",
                type: "Breathing",
                steps: [
                    "Close your eyes",
                    "Notice your natural breath",
                    "Count each breath from 1 to 10",
                    "Start over if you lose count",
                    "Feel the calm settle in"
                ]
            )
        ]
    }
}

struct MeditationSession: Identifiable {
    let id = UUID()
    let title: String
    let duration: Int
    let description: String
    let icon: String
    let type: String
    let steps: [String]
}

struct MeditationSessionCard: View {
    let session: MeditationSession
    let onStart: () -> Void
    
    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 16) {
                Image(systemName: session.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(session.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("\(session.duration) min")
                            .font(.caption)
                            .foregroundColor(.purple)
                        Text("•")
                            .font(.caption)
                        Text(session.type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct MeditationSessionDetailView: View {
    let session: MeditationSession
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: session.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                        .padding(.top, 40)
                    
                    Text(session.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(session.type)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Duration Badge
                    HStack {
                        Image(systemName: "clock")
                        Text("\(session.duration) minutes")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.purple.opacity(0.1))
                    )
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meditation Guide")
                            .font(.headline)
                        
                        ForEach(Array(session.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color.purple.opacity(0.1))
                                    )
                                
                                Text(step)
                                    .font(.body)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    Button {
                        // Start meditation
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Begin Meditation")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple)
                        )
                    }
                    .padding(.horizontal)
                    
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

struct MeditationTipCard: View {
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
    DailyMeditationView(userAnswers: [:])
}
