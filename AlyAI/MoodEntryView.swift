import SwiftUI

// MARK: - Mood Enum (FIX)
enum Mood: String, CaseIterable, Identifiable, Codable {
    case calm
    case happy
    case sad
    case anxious
    case irritable
    case tired
    case energized
    case overwhelmed
    case low
    case motivated

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .happy: return "😊"
        case .sad: return "😢"
        case .anxious: return "😟"
        case .irritable: return "😠"
        case .tired: return "😴"
        case .energized: return "⚡️"
        case .overwhelmed: return "😵"
        case .low: return "⬇️"
        case .motivated: return "🔥"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Mood Entry View
struct MoodEntryView: View {
    let date: Date
    @Binding var selectedMood: Mood?
    @Environment(\.dismiss) private var dismiss

    let moods = Mood.allCases

    var body: some View {
        VStack(spacing: 20) {
            Text("How are you feeling?")
                .font(.title)
                .fontWeight(.bold)

            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
                .foregroundColor(Color.textSecondary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 20
            ) {
                ForEach(moods) { mood in
                    Button {
                        selectedMood = mood
                        dismiss()
                    } label: {
                        VStack(spacing: 8) {
                            Text(mood.emoji)
                                .font(.largeTitle)

                            Text(mood.displayName)
                                .font(.caption)
                                .foregroundColor(Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedMood == mood
                            ? Color.accentPrimary.opacity(0.25)
                            : Color.textSecondary.opacity(0.1)
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding()

            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(Color.textSecondary)
        }
        .padding()
    }
}
