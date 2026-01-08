import SwiftUI

struct AnimatedBreathingGuideView: View {
    let technique: BreathingTechnique
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAnimating = false
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var countdown: Int = 4
    @State private var cycleCount: Int = 0
    @State private var isActive: Bool = false
    @State private var timer: Timer?
    
    enum BreathingPhase {
        case inhale, hold1, exhale, hold2
        
        var displayText: String {
            switch self {
            case .inhale: return "Inhale"
            case .hold1: return "Hold"
            case .exhale: return "Exhale"
            case .hold2: return "Hold"
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe in slowly through your nose"
            case .hold1: return "Hold your breath gently"
            case .exhale: return "Breathe out slowly through your mouth"
            case .hold2: return "Hold before the next breath"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.7, blue: 0.9).opacity(0.3),
                        Color(red: 0.6, green: 0.8, blue: 1.0).opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header
                    VStack(spacing: 8) {
                        Text(technique.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Cycle \(cycleCount + 1) of 10")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Animated Circle
                    ZStack {
                        // Outer glow circle
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.blue.opacity(0.3),
                                        Color.blue.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: isAnimating ? 80 : 40,
                                    endRadius: isAnimating ? 180 : 120
                                )
                            )
                            .frame(width: isAnimating ? 280 : 180, height: isAnimating ? 280 : 180)
                            .animation(.easeInOut(duration: animationDuration), value: isAnimating)
                        
                        // Main breathing circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.7),
                                        Color.blue.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: isAnimating ? 220 : 140, height: isAnimating ? 220 : 140)
                            .shadow(color: Color.blue.opacity(0.5), radius: isAnimating ? 30 : 15)
                            .animation(.easeInOut(duration: animationDuration), value: isAnimating)
                        
                        // Countdown number
                        Text("\(countdown)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    // Phase instruction
                    VStack(spacing: 16) {
                        Text(currentPhase.displayText)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(currentPhase.instruction)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(height: 100)
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 20) {
                        // Pause/Play button
                        Button(action: toggleAnimation) {
                            Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                        
                        // Stop button
                        Button(action: stopAnimation) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        stopAnimation()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
        }
    }
    
    // MARK: - Animation Control
    
    private var animationDuration: Double {
        Double(countdown)
    }
    
    private func startAnimation() {
        isActive = true
        cycleCount = 0
        startBreathingCycle()
    }
    
    private func toggleAnimation() {
        if isActive {
            pauseAnimation()
        } else {
            resumeAnimation()
        }
    }
    
    private func pauseAnimation() {
        isActive = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeAnimation() {
        isActive = true
        startBreathingCycle()
    }
    
    private func stopAnimation() {
        isActive = false
        timer?.invalidate()
        timer = nil
        cycleCount = 0
    }
    
    private func startBreathingCycle() {
        guard isActive else { return }
        
        // Start with inhale phase
        currentPhase = .inhale
        countdown = technique.inhaleDuration
        isAnimating = true
        
        startPhaseTimer()
    }
    
    private func startPhaseTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard isActive else { return }
            
            if countdown > 1 {
                countdown -= 1
            } else {
                // Move to next phase
                moveToNextPhase()
            }
        }
    }
    
    private func moveToNextPhase() {
        switch currentPhase {
        case .inhale:
            if technique.holdDuration1 > 0 {
                currentPhase = .hold1
                countdown = technique.holdDuration1
                isAnimating = true
            } else {
                currentPhase = .exhale
                countdown = technique.exhaleDuration
                isAnimating = false
            }
            
        case .hold1:
            currentPhase = .exhale
            countdown = technique.exhaleDuration
            isAnimating = false
            
        case .exhale:
            if technique.holdDuration2 > 0 {
                currentPhase = .hold2
                countdown = technique.holdDuration2
                isAnimating = false
            } else {
                // Complete cycle
                completeCycle()
            }
            
        case .hold2:
            completeCycle()
        }
    }
    
    private func completeCycle() {
        cycleCount += 1
        
        if cycleCount >= 10 {
            // Finished all cycles
            stopAnimation()
        } else {
            // Start next cycle
            startBreathingCycle()
        }
    }
}

// MARK: - Breathing Technique Model

struct BreathingTechnique {
    let name: String
    let inhaleDuration: Int
    let holdDuration1: Int
    let exhaleDuration: Int
    let holdDuration2: Int
    
    static let boxBreathing = BreathingTechnique(
        name: "Box Breathing",
        inhaleDuration: 4,
        holdDuration1: 4,
        exhaleDuration: 4,
        holdDuration2: 4
    )
    
    static let breathing478 = BreathingTechnique(
        name: "4-7-8 Breathing",
        inhaleDuration: 4,
        holdDuration1: 7,
        exhaleDuration: 8,
        holdDuration2: 0
    )
    
    static let deepBelly = BreathingTechnique(
        name: "Deep Belly Breathing",
        inhaleDuration: 5,
        holdDuration1: 0,
        exhaleDuration: 6,
        holdDuration2: 0
    )
    
    static let alternateNostril = BreathingTechnique(
        name: "Alternate Nostril",
        inhaleDuration: 4,
        holdDuration1: 4,
        exhaleDuration: 4,
        holdDuration2: 4
    )
}

#Preview {
    AnimatedBreathingGuideView(technique: .boxBreathing)
}
