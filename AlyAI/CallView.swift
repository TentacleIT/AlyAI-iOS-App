import SwiftUI

struct CallView: View {
    @EnvironmentObject var userSession: UserSession
    let userAnswers: [String: Any]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = CallSessionManager()
    @ObservedObject var chatStore: ChatStore
    
    // Animation state
    @State private var wavePhase: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            backgroundLayer
            
            VStack(spacing: 40) {
                Spacer()
                
                identitySection
                
                waveformView
                
                Spacer()
                
                timerView
                
                controlsView
                    .padding(.bottom, 10)
                
                endCallButton
                    .padding(.bottom, 50)
                
                disclaimerView
            }
        }
        .onAppear {
            var context = userAnswers
            context["name"] = userSession.userName
            sessionManager.context = context
            sessionManager.startSession()
        }
        .onDisappear {
            sessionManager.endSession()
        }
        .onChange(of: sessionManager.transcript) { oldValue, newValue in
            // Optional: Live transcript update if desired, but request says "Centered elements only"
        }
        .onChange(of: sessionManager.aiResponse) { oldValue, newValue in
            if !newValue.isEmpty {
                 // Add to chat history when AI responds (or we can do it when session ends)
                 // Doing it here captures the turn
                 chatStore.addMessage(sessionManager.transcript, isUser: true)
                 chatStore.addMessage(newValue, isUser: false)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundLayer: some View {
        ZStack {
            Color.alyBackground.ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [Color.alyaiPrimary.opacity(0.1), Color.alyBackground]),
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    private var identitySection: some View {
        VStack(spacing: 16) {
            Text("AlyAI")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.alyTextPrimary)
            
            Text(statusText)
                .font(.title3)
                .foregroundColor(.alyTextSecondary)
                .animation(.easeInOut, value: sessionManager.state)
        }
    }
    
    private var waveformView: some View {
        ZStack {
            // Central orb
            Circle()
                .fill(stateColor.opacity(0.2))
                .frame(width: 150, height: 150)
                .blur(radius: 20)
            
            if sessionManager.state == .listening {
                // Audio reactive waves
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(stateColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 150, height: 150)
                        .scaleEffect(1.0 + CGFloat(sessionManager.audioLevel) * 2.0 + (CGFloat(i) * 0.1))
                        .opacity(1.0 - Double(sessionManager.audioLevel))
                        .animation(.easeOut(duration: 0.2), value: sessionManager.audioLevel)
                }
            } else if sessionManager.state == .speaking {
                // AI speaking animation (simulated)
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(stateColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 150 + CGFloat(i * 20), height: 150 + CGFloat(i * 20))
                        .scaleEffect(1.0 + 0.1 * CGFloat(sin(Double(wavePhase) + Double(i))))
                        .opacity(0.8)
                }
            } else if sessionManager.state == .processing {
                // Thinking pulsing
                Circle()
                    .stroke(stateColor, lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .scaleEffect(1.0 + 0.1 * CGFloat(sin(Double(wavePhase))))
                    .opacity(0.5 + 0.5 * cos(Double(wavePhase)))
            }
        }
        .frame(height: 300)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }
    
    private var timerView: some View {
        Text(timeString(time: sessionManager.callDuration))
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.gray)
    }
    
    private var controlsView: some View {
        HStack(spacing: 60) {
            // Mute Button
            Button {
                sessionManager.toggleMute()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(sessionManager.isMuted ? Color.alyTextPrimary : Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: sessionManager.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(sessionManager.isMuted ? .white : .alyTextPrimary)
                    }
                    Text("Mute")
                        .font(.caption)
                        .foregroundColor(.alyTextSecondary)
                }
            }
            
            // Speaker Button
            Button {
                sessionManager.toggleSpeaker()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(sessionManager.isSpeakerOn ? Color.alyTextPrimary : Color.gray.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: sessionManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.title2)
                            .foregroundColor(sessionManager.isSpeakerOn ? .white : .alyTextPrimary)
                    }
                    Text("Speaker")
                        .font(.caption)
                        .foregroundColor(.alyTextSecondary)
                }
            }
        }
    }
    
    private var endCallButton: some View {
        Button {
            endCall()
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: "F56565")) // Red color
                    .frame(width: 72, height: 72)
                    .shadow(color: Color(hex: "F56565").opacity(0.4), radius: 10)
                
                Image(systemName: "phone.down.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
    
    private var disclaimerView: some View {
        Text("AlyAI is not a replacement for professional care")
            .font(.caption)
            .foregroundColor(.gray.opacity(0.5))
            .padding(.bottom, 20)
    }
    
    private func endCall() {
        sessionManager.endSession()
        dismiss()
    }
    
    private var statusText: String {
        switch sessionManager.state {
        case .idle: return "Connecting..."
        case .listening: return "Listening..."
        case .processing: return "Thinking..."
        case .speaking: return "Speaking..."
        case .ending: return "Ending call..."
        case .error(let msg): return msg
        }
    }
    
    private var stateColor: Color {
        switch sessionManager.state {
        case .listening: return .alyaiPrimary
        case .speaking: return .blue
        case .processing: return .purple
        case .error: return .red
        default: return .gray
        }
    }
    
    private func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
