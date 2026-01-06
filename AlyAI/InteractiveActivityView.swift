import SwiftUI
import Combine

// MARK: - Activity Types

enum ActivityType {
    case mindfulness
    case anxiety
    case cognitive
    case sleep
    case mood
    case affirmation
    case generic
}

// MARK: - Main Interactive View

struct InteractiveActivityView: View {
    let activityType: ActivityType
    let title: String
    let description: String
    var onComplete: ((String?) -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background based on type
            backgroundForType(activityType)
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.backgroundPrimary.opacity(0.8))
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Specific Activity Content
                switch activityType {
                case .mindfulness:
                    MindfulnessSessionView(title: title, onComplete: finishActivity)
                case .anxiety:
                    AnxietyReliefView(title: title, onComplete: finishActivity)
                case .cognitive:
                    CognitiveReframingView(title: title, onComplete: finishActivity)
                case .sleep:
                    SleepWindDownView(title: title, onComplete: finishActivity)
                case .mood:
                    MoodTrackingView(title: title, onComplete: finishActivity)
                case .affirmation:
                    AffirmationSessionView(title: title, onComplete: finishActivity)
                case .generic:
                    GenericActivityView(title: title, description: description, onComplete: finishActivity)
                }
                
                Spacer()
            }
        }
    }
    
    private func finishActivity(_ result: String? = nil) {
        onComplete?(result)
        dismiss()
    }
    
    private func backgroundForType(_ type: ActivityType) -> Color {
        switch type {
        case .mindfulness: return Color.accentPrimary
        case .anxiety: return Color.success
        case .cognitive: return Color.accentPrimary
        case .sleep: return Color(light: "#1A1B4B", dark: "#1A1B4B")
        case .mood: return Color.warning
        case .affirmation: return Color.success
        case .generic: return Color.backgroundPrimary
        }
    }
}

// MARK: - 1. Mindfulness Session (Guided Meditation)

struct MindfulnessSessionView: View {
    let title: String
    let onComplete: (String?) -> Void
    
    @State private var timeRemaining = 180 // 3 minutes total
    @State private var isActive = false
    @State private var showCompletion = false
    @State private var currentPromptIndex = 0
    @State private var promptOpacity = 0.0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Guided prompts for meditation (Non-breathing focused)
    let prompts = [
        "Find a comfortable position and gently close your eyes.",
        "Bring your attention to the sensation of your body sitting here.",
        "Notice any thoughts passing through your mind, like clouds in the sky.",
        "Do not judge your thoughts, just observe them drifting by.",
        "If you get distracted, gently bring your focus back to the present moment.",
        "Take a moment to appreciate this stillness."
    ]
    
    // Cycle prompts every 30 seconds
    private let promptInterval = 30
    
    var body: some View {
        VStack(spacing: 30) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.backgroundPrimary)
                .multilineTextAlignment(.center)
            
            if showCompletion {
                completionView
            } else {
                VStack(spacing: 50) {
                    
                    // Meditation Visual (Abstract, slow, non-rhythmic)
                    ZStack {
                        // Soft glowing background
                        Circle()
                            .fill(Color.backgroundPrimary.opacity(0.05))
                            .frame(width: 300, height: 300)
                            .blur(radius: 20)
                        
                        // Floating content
                        VStack(spacing: 24) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(Color.backgroundPrimary.opacity(0.6))
                                .offset(y: isActive ? -10 : 10)
                                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isActive)
                            
                            Text(prompts[currentPromptIndex])
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(Color.backgroundPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .opacity(promptOpacity)
                                .id(currentPromptIndex) // Force transition
                        }
                    }
                    .frame(height: 300)
                    .onAppear {
                        isActive = true
                        withAnimation(.easeIn(duration: 2.0)) {
                            promptOpacity = 1.0
                        }
                    }
                    
                    // Timer Display
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 24, design: .monospaced))
                        .foregroundColor(Color.backgroundPrimary.opacity(0.7))
                    
                    Button {
                        isActive.toggle()
                    } label: {
                        Text(isActive ? "Pause Session" : "Resume")
                            .fontWeight(.semibold)
                            .foregroundColor(Color.textPrimary)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.backgroundPrimary))
                    }
                }
                .onReceive(timer) { _ in
                    if isActive {
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                            
                            // Change prompt based on interval
                            let elapsedTime = 180 - timeRemaining
                            let newIndex = min(elapsedTime / promptInterval, prompts.count - 1)
                            if newIndex != currentPromptIndex {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    promptOpacity = 0.0 // Fade out
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    currentPromptIndex = newIndex
                                    withAnimation(.easeIn(duration: 1.0)) {
                                        promptOpacity = 1.0 // Fade in
                                    }
                                }
                            }
                            
                        } else {
                            isActive = false
                            showCompletion = true
                        }
                    }
                }
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(Color.backgroundPrimary)
                .scaleEffect(1.1)
                .animation(.easeInOut(duration: 2).repeatForever(), value: true)
            
            Text("Session Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.backgroundPrimary)
            
            Text("You have strengthened your mental clarity.")
                .foregroundColor(Color.backgroundPrimary.opacity(0.8))
            
            Button("Done") {
                onComplete(nil)
            }
            .fontWeight(.bold)
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(Capsule().fill(Color.backgroundPrimary))
            .padding(.top, 20)
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - 2. Anxiety Relief (4-7-8 Breathing)

struct AnxietyReliefView: View {
    let title: String
    let onComplete: (String?) -> Void
    
    @State private var phase = "Inhale"
    @State private var phaseTime = 4
    @State private var currentCycle = 1
    @State private var totalCycles = 4
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 40) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.backgroundPrimary)
            
            ZStack {
                Circle()
                    .fill(Color.backgroundPrimary.opacity(0.3))
                    .frame(width: 280, height: 280)
                    .scaleEffect(scale)
                
                VStack {
                    Text(phase)
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(Color.backgroundPrimary)
                        .transition(.opacity)
                        .id("PhaseText\(phase)") // Force transition
                    
                    Text("\(phaseTime)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(Color.backgroundPrimary)
                        .contentTransition(.numericText())
                }
            }
            .onAppear(perform: startCycle)
            
            Text("Cycle \(currentCycle) of \(totalCycles)")
                .font(.headline)
                .foregroundColor(Color.backgroundPrimary.opacity(0.8))
        }
    }
    
    func startCycle() {
        if currentCycle > totalCycles {
            onComplete(nil)
            return
        }
        
        // Inhale: 4s
        phase = "Inhale"
        withAnimation(.easeInOut(duration: 4)) {
            scale = 1.5
            opacity = 1.0
        }
        runTimer(seconds: 4) {
            // Hold: 7s
            phase = "Hold"
            withAnimation(.linear(duration: 7)) {
                scale = 1.5 // Stay expanded
            }
            runTimer(seconds: 7) {
                // Exhale: 8s
                phase = "Exhale"
                withAnimation(.easeInOut(duration: 8)) {
                    scale = 1.0
                    opacity = 0.5
                }
                runTimer(seconds: 8) {
                    currentCycle += 1
                    startCycle()
                }
            }
        }
    }
    
    func runTimer(seconds: Int, completion: @escaping () -> Void) {
        phaseTime = seconds
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if phaseTime > 1 {
                phaseTime -= 1
            } else {
                timer.invalidate()
                completion()
            }
        }
    }
}

// MARK: - 3. Cognitive Reframing (Wizard)

struct CognitiveReframingView: View {
    let title: String
    let onComplete: (String?) -> Void
    
    @State private var step = 0
    @State private var inputText = ""
    
    let steps = [
        "What is the thought that is bothering you?",
        "Is this thought 100% true? Can you prove it?",
        "How does this thought make you feel?",
        "What is a more helpful or realistic way to see this?"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(step + 1), total: Double(steps.count))
                .tint(Color.backgroundPrimary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 20) {
                Text("Step \(step + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color.backgroundPrimary.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.backgroundPrimary.opacity(0.2)))
                
                Text(steps[step])
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.backgroundPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Type your answer...", text: $inputText)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.backgroundPrimary))
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                nextStep()
            } label: {
                Text(step < steps.count - 1 ? "Next" : "Complete")
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary) // Use black for contrast on white button
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.backgroundPrimary))
            }
            .padding()
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
        }
        .padding()
    }
    
    func nextStep() {
        if step < steps.count - 1 {
            withAnimation {
                step += 1
                inputText = ""
            }
        } else {
            onComplete("User reframed a thought.")
        }
    }
}

// MARK: - 4. Sleep Wind Down

struct SleepWindDownView: View {
    let title: String
    let onComplete: (String?) -> Void
    
    @State private var showContent = false
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.warning.opacity(0.8))
                .shadow(color: Color.warning.opacity(0.5), radius: 20)
                .scaleEffect(showContent ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 3).repeatForever(), value: showContent)
            
            if showContent {
                Text(title)
                    .font(.title)
                    .foregroundColor(Color.backgroundPrimary)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            if showDetails {
                Text("Let go of the day.\nBreathe slowly.\nRelax your shoulders.")
                    .font(.title3)
                    .foregroundColor(Color.backgroundPrimary.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Spacer()
            
            Button("I'm feeling sleepier") {
                onComplete(nil)
            }
            .foregroundColor(Color.backgroundPrimary)
            .padding(.bottom, 40)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 2)) {
                showContent = true
            }
            withAnimation(.easeIn(duration: 2).delay(1.0)) {
                showDetails = true
            }
        }
    }
}

// MARK: - 5. Mood Tracking Activity

struct MoodTrackingView: View {
    let title: String
    let onComplete: (String?) -> Void
    
    @State private var selectedMood: String?
    @State private var note: String = ""
    @State private var isSaved = false
    
    let moods = [
        ("Great", "star.fill", Color.warning),
        ("Good", "face.smiling.fill", Color.success),
        ("Okay", "face.dashed", Color.accentPrimary),
        ("Low", "cloud.rain.fill", Color.textSecondary),
        ("Anxious", "tornado", Color.warning)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.backgroundPrimary)
                .multilineTextAlignment(.center)
            
            if isSaved {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.backgroundPrimary)
                        .scaleEffect(1.2)
                        .transition(.scale)
                    
                    Text("Mood Logged")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.backgroundPrimary)
                    
                    Button("Done") {
                        onComplete("Mood: \(selectedMood ?? "Unknown"), Note: \(note)")
                    }
                    .padding(.top, 20)
                    .foregroundColor(Color.backgroundPrimary)
                    .fontWeight(.bold)
                }
            } else {
                VStack(spacing: 40) {
                    Text("How are you feeling right now?")
                        .font(.title3)
                        .foregroundColor(Color.backgroundPrimary.opacity(0.9))
                    
                    HStack(spacing: 12) {
                        ForEach(moods, id: \.0) { mood in
                            VStack {
                                Image(systemName: mood.1)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedMood == mood.0 ? Color.backgroundPrimary : Color.backgroundPrimary.opacity(0.5))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(selectedMood == mood.0 ? mood.2 : Color.backgroundPrimary.opacity(0.1))
                                    )
                                    .scaleEffect(selectedMood == mood.0 ? 1.1 : 1.0)
                                    .animation(.spring(), value: selectedMood)
                                
                                Text(mood.0)
                                    .font(.caption)
                                    .foregroundColor(Color.backgroundPrimary)
                            }
                            .onTapGesture {
                                selectedMood = mood.0
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("What's influencing your mood?")
                            .font(.caption)
                            .foregroundColor(Color.backgroundPrimary.opacity(0.8))
                            .padding(.leading, 4)
                        
                        TextField("Optional note...", text: $note)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.backgroundPrimary.opacity(0.2)))
                            .foregroundColor(Color.backgroundPrimary)
                    }
                    .padding(.horizontal)
                    
                    Button {
                        withAnimation {
                            isSaved = true
                        }
                    } label: {
                        Text("Save Entry")
                            .fontWeight(.bold)
                            .foregroundColor(selectedMood == nil ? Color.backgroundPrimary.opacity(0.5) : Color.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(selectedMood == nil ? Color.textSecondary.opacity(0.3) : Color.backgroundPrimary))
                    }
                    .padding(.horizontal)
                    .disabled(selectedMood == nil)
                }
            }
        }
        .padding()
    }
}

// MARK: - 6. Affirmation Session

struct AffirmationSessionView: View {
    let title: String
    let onComplete: (String?) -> Void
    
    @State private var index = 0
    @State private var opacity = 0.0
    
    // In a real app, these would come from the assessment result or API
    let affirmations = [
        "I am enough just as I am.",
        "I trust myself to handle whatever comes.",
        "My feelings are valid and I accept them.",
        "I choose peace over perfection.",
        "I am becoming stronger every day."
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.backgroundPrimary.opacity(0.8))
                .padding(.top)
            
            Spacer()
            
            ZStack {
                ForEach(0..<affirmations.count, id: \.self) { i in
                    if i == index {
                        Text(affirmations[i])
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(Color.backgroundPrimary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .transition(.opacity.combined(with: .scale))
                            .id(i)
                    }
                }
            }
            .frame(height: 200)
            
            Spacer()
            
            Button {
                nextAffirmation()
            } label: {
                Text(index < affirmations.count - 1 ? "Next Affirmation" : "Complete")
                    .fontWeight(.bold)
                    .foregroundColor(Color.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Capsule().fill(Color.backgroundPrimary))
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 1.0
            }
        }
    }
    
    func nextAffirmation() {
        if index < affirmations.count - 1 {
            withAnimation {
                index += 1
            }
        } else {
            onComplete(nil)
        }
    }
}

// MARK: - 7. Generic Activity

struct GenericActivityView: View {
    let title: String
    let description: String
    let onComplete: (String?) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Color.accentPrimary)
                .padding()
                .background(Circle().fill(Color.backgroundPrimary.opacity(0.2)))
            
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.accentPrimary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .foregroundColor(Color.textPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Button("Complete Activity") {
                onComplete(nil)
            }
            .fontWeight(.bold)
            .foregroundColor(Color.textPrimary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(Color.backgroundPrimary))
            .padding()
        }
        .padding()
    }
}
