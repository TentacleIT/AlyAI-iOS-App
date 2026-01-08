import SwiftUI

struct JournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var journalText: String = ""
    @State private var mood: String = ""
    @State private var showSaveConfirmation = false
    
    let moods = ["😊 Happy", "😌 Calm", "😔 Sad", "😰 Anxious", "😤 Frustrated", "🥰 Grateful"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.65, green: 0.55, blue: 0.90), Color(red: 0.55, green: 0.45, blue: 0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Journal Entry")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Express your thoughts and feelings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    // Mood Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling?")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(moods, id: \.self) { moodOption in
                                    Button(action: {
                                        mood = moodOption
                                    }) {
                                        Text(moodOption)
                                            .font(.system(size: 16))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                mood == moodOption ?
                                                Color(red: 0.65, green: 0.55, blue: 0.90) :
                                                Color.gray.opacity(0.1)
                                            )
                                            .foregroundColor(
                                                mood == moodOption ? .white : .primary
                                            )
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Journal Text Area
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's on your mind?")
                            .font(.headline)
                        
                        ZStack(alignment: .topLeading) {
                            if journalText.isEmpty {
                                Text("Write your thoughts here...\n\nYou can write about:\n• What happened today\n• How you're feeling\n• What you're grateful for\n• Your goals and dreams\n• Anything on your mind")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                            }
                            
                            TextEditor(text: $journalText)
                                .frame(minHeight: 250)
                                .padding(4)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save Button
                    Button(action: {
                        saveJournalEntry()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Entry")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.55, blue: 0.90), Color(red: 0.55, green: 0.45, blue: 0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .disabled(journalText.isEmpty)
                    .opacity(journalText.isEmpty ? 0.5 : 1.0)
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 Journaling Tips")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(icon: "lightbulb.fill", text: "Write freely without judgment")
                            TipRow(icon: "heart.fill", text: "Focus on your feelings and emotions")
                            TipRow(icon: "star.fill", text: "Note what you're grateful for")
                            TipRow(icon: "target", text: "Set intentions for tomorrow")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert("Entry Saved!", isPresented: $showSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your journal entry has been saved successfully.")
            }
        }
    }
    
    private func saveJournalEntry() {
        // TODO: Implement actual saving to database/storage
        // For now, just show confirmation
        print("📝 [JournalEntry] Saving entry...")
        print("Mood: \(mood)")
        print("Text: \(journalText)")
        
        showSaveConfirmation = true
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.65, green: 0.55, blue: 0.90))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    JournalEntryView()
}
