import SwiftUI

struct MindEmotionsView: View {
    let userAnswers: [String: Any]
    var title: String = "Mind & Emotions"
    @State private var currentMood: MoodLevel = .neutral
    @State private var journalEntries: [JournalEntry] = []
    @State private var showJournalSheet = false
    @State private var selectedPractice: MindfulnessPractice?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.alyaiEmotional)
                        
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Track your emotional wellness and practice mindfulness")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Mood Tracker
                    moodTrackerCard
                    
                    // Mindfulness Practices
                    mindfulnessPracticesSection
                    
                    // Journal Entries
                    journalSection
                    
                    // Emotional Wellness Tips
                    emotionalTipsSection
                    
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
        .sheet(isPresented: $showJournalSheet) {
            JournalEntrySheet { entry in
                journalEntries.insert(entry, at: 0)
            }
        }
        .onAppear {
            loadSampleData()
        }
    }
    
    private var moodTrackerCard: some View {
        VStack(spacing: 20) {
            Text("How are you feeling today?")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(MoodLevel.allCases, id: \.self) { mood in
                    MoodButton(mood: mood, isSelected: currentMood == mood) {
                        currentMood = mood
                    }
                }
            }
            
            if currentMood != .neutral {
                Text(currentMood.encouragement)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.alyaiLightPurple.opacity(0.2))
        )
    }
    
    private var mindfulnessPracticesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mindfulness Practices")
                .font(.headline)
            
            ForEach(getMindfulnessPractices()) { practice in
                PracticeCard(practice: practice) {
                    selectedPractice = practice
                }
            }
        }
    }
    
    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reflection Journal")
                    .font(.headline)
                Spacer()
                Button {
                    showJournalSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.alyaiEmotional)
                }
            }
            
            if journalEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No journal entries yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Start reflecting on your day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            } else {
                ForEach(journalEntries) { entry in
                    JournalCard(entry: entry)
                }
            }
        }
    }
    
    private var emotionalTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emotional Wellness Tips")
                .font(.headline)
            
            MindEmotionsTipRow(icon: "heart.fill", title: "Practice Gratitude", description: "List 3 things you're grateful for", color: .red)
            MindEmotionsTipRow(icon: "figure.mind.and.body", title: "Mindful Breathing", description: "Take 5 deep breaths when stressed", color: .alyaiEmotional)
            MindEmotionsTipRow(icon: "person.2.fill", title: "Connect with Others", description: "Reach out to a friend or loved one", color: .blue)
        }
    }
    
    private func getMindfulnessPractices() -> [MindfulnessPractice] {
        return [
            MindfulnessPractice(
                title: "Body Scan Meditation",
                duration: 10,
                description: "Relax and connect with your body",
                icon: "figure.mind.and.body",
                steps: [
                    "Find a comfortable position",
                    "Close your eyes and breathe deeply",
                    "Focus on each part of your body",
                    "Notice sensations without judgment"
                ]
            ),
            MindfulnessPractice(
                title: "Loving-Kindness Meditation",
                duration: 15,
                description: "Cultivate compassion and self-love",
                icon: "heart.circle.fill",
                steps: [
                    "Sit comfortably and close your eyes",
                    "Repeat: 'May I be happy, may I be healthy'",
                    "Extend these wishes to others",
                    "Feel warmth and compassion grow"
                ]
            ),
            MindfulnessPractice(
                title: "Mindful Walking",
                duration: 10,
                description: "Be present with each step",
                icon: "figure.walk",
                steps: [
                    "Walk slowly and deliberately",
                    "Notice your feet touching the ground",
                    "Observe your surroundings",
                    "Breathe in sync with your steps"
                ]
            )
        ]
    }
    
    private func loadSampleData() {
        journalEntries = [
            JournalEntry(mood: .happy, content: "Had a great day connecting with friends. Feeling grateful!", date: Date().addingTimeInterval(-86400)),
            JournalEntry(mood: .neutral, content: "Practiced meditation for 15 minutes. Feeling centered and peaceful.", date: Date().addingTimeInterval(-172800))
        ]
    }
}

// MARK: - Models

enum MoodLevel: CaseIterable {
    case veryHappy, happy, neutral, sad, stressed
    
    var icon: String {
        switch self {
        case .veryHappy: return "face.smiling.fill"
        case .happy: return "face.smiling"
        case .neutral: return "face.dashed"
        case .sad: return "cloud.rain"
        case .stressed: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .veryHappy: return .green
        case .happy: return .blue
        case .neutral: return .gray
        case .sad: return .orange
        case .stressed: return .red
        }
    }
    
    var label: String {
        switch self {
        case .veryHappy: return "Great"
        case .happy: return "Good"
        case .neutral: return "Okay"
        case .sad: return "Down"
        case .stressed: return "Stressed"
        }
    }
    
    var encouragement: String {
        switch self {
        case .veryHappy: return "Wonderful! Keep nurturing this positive energy."
        case .happy: return "That's great to hear! You're doing well."
        case .neutral: return "That's okay. Every day is different."
        case .sad: return "I'm here for you. Be gentle with yourself."
        case .stressed: return "Take a deep breath. You've got this."
        }
    }
}

struct MindfulnessPractice: Identifiable {
    let id = UUID()
    let title: String
    let duration: Int
    let description: String
    let icon: String
    let steps: [String]
}

struct JournalEntry: Identifiable {
    let id = UUID()
    let mood: MoodLevel
    let content: String
    let date: Date
}

// MARK: - Supporting Views

struct MoodButton: View {
    let mood: MoodLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mood.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? mood.color : .gray)
                
                Text(mood.label)
                    .font(.caption)
                    .foregroundColor(isSelected ? mood.color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.color.opacity(0.1) : Color(.systemGray6))
            )
        }
    }
}

struct PracticeCard: View {
    let practice: MindfulnessPractice
    let onStart: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: practice.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.alyaiEmotional)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(practice.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(practice.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(practice.duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Steps:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(practice.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.alyaiEmotional)
                            Text(step)
                                .font(.subheadline)
                        }
                    }
                }
                
                Button {
                    onStart()
                } label: {
                    Text("Start Practice")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.alyaiEmotional)
                        )
                        .foregroundColor(.white)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct JournalCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.mood.icon)
                    .foregroundColor(entry.mood.color)
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(entry.content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.alyaiLightPurple.opacity(0.1))
        )
    }
}

struct MindEmotionsTipRow: View {
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

// MARK: - Journal Entry Sheet

struct JournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (JournalEntry) -> Void
    
    @State private var selectedMood: MoodLevel = .neutral
    @State private var journalText = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("How are you feeling?") {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(MoodLevel.allCases, id: \.self) { mood in
                            HStack {
                                Image(systemName: mood.icon)
                                Text(mood.label)
                            }
                            .tag(mood)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Your thoughts") {
                    TextField("Write your reflections...", text: $journalText, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("New Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onAdd(JournalEntry(mood: selectedMood, content: journalText, date: Date()))
                        dismiss()
                    }
                    .disabled(journalText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MindEmotionsView(userAnswers: [:])
}
