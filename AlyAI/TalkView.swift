import SwiftUI
import AVFoundation

struct TalkView: View {
    let userAnswers: [String: Any]
    @ObservedObject var chatStore: ChatStore
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var speechManager = SpeechManager()
    @State private var isThinking = false
    @State private var conversationStatus = "Tap to speak"
    @State private var alyaiTranscript = ""
    
    // Animation states
    @State private var waveScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.accentPrimary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Status Indicator
                VStack(spacing: 20) {
                    if isThinking {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(Color.accentPrimary)
                    }
                    
                    Text(conversationStatus)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .animation(.easeInOut, value: conversationStatus)
                    
                    if !speechManager.transcript.isEmpty {
                        Text("\"\(speechManager.transcript)\"")
                            .font(.headline)
                            .italic()
                            .foregroundColor(Color.accentPrimary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.surfacePrimary)
                                    .shadow(color: Color.shadow, radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal, 32)
                            .transition(.opacity)
                    }
                    
                    if !alyaiTranscript.isEmpty {
                        Text(alyaiTranscript)
                            .font(.body)
                            .foregroundColor(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.surfacePrimary.opacity(0.9))
                                    .shadow(color: Color.shadow, radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal, 32)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // Microphone Button
                ZStack {
                    // Pulsing waves when active
                    if speechManager.isRecording || speechManager.isSpeaking {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.accentPrimary.opacity(0.3), lineWidth: 2)
                                .scaleEffect(waveScale)
                                .opacity(2 - waveScale)
                                .animation(
                                    Animation.easeOut(duration: 1.5)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 0.5),
                                    value: waveScale
                                )
                        }
                    }
                    
                    Button {
                        if speechManager.isRecording {
                            finishListening()
                        } else if speechManager.isSpeaking || isThinking {
                            stopInteraction()
                        } else {
                            startListening()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.alyaiGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.accentPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: speechManager.isRecording ? "waveform" : (speechManager.isSpeaking ? "speaker.wave.2.fill" : "mic.fill"))
                                .font(.system(size: 40))
                                .foregroundColor(Color.backgroundPrimary)
                                .symbolEffect(.bounce, value: speechManager.isRecording)
                        }
                    }
                }
                .padding(.bottom, 60)
                .onAppear {
                    waveScale = 2.0
                }
                .onChange(of: speechManager.isSpeaking) { oldValue, newValue in
                    if newValue {
                        conversationStatus = "Speaking..."
                    } else if !newValue && !speechManager.isRecording && !isThinking {
                        conversationStatus = "Tap to reply"
                    }
                }
                .onChange(of: speechManager.errorMessage) { oldValue, newValue in
                    if let error = newValue {
                        conversationStatus = error
                    }
                }
            }
        }
    }
    
    private func startListening() {
        if !speechManager.permissionGranted {
            conversationStatus = "Microphone access denied"
            return
        }
        conversationStatus = "Listening..."
        speechManager.startRecording()
    }
    
    private func finishListening() {
        speechManager.stopRecording()
        
        // Wait briefly for final recognition?
        // Actually stopRecording stops engine immediately.
        
        if speechManager.transcript.isEmpty {
            conversationStatus = "I didn\'t hear anything"
            return
        }
        
        isThinking = true
        conversationStatus = "Thinking..."
        
        processResponse()
    }
    
    private func processResponse() {
        let userInput = speechManager.transcript
        
        // Add user message to chat history
        chatStore.addMessage(userInput, isUser: true)
        
        // Clear previous ALYAI transcript while thinking
        alyaiTranscript = ""
        
        let currentFocus = userAnswers["current_focus"] as? String ?? "wellness"
        let nameRaw = userAnswers["name"] as? String
        let name = (nameRaw?.isEmpty == false) ? nameRaw! : "Friend"
        let activityHistory = ActivityManager.shared.getHistoryForOpenAI()
        
        let prompt = """
        The user’s name is \(name).
        Address the user by name naturally and warmly.
        Do not use generic greetings such as ‘Hello Friend’ or ‘Hi there’ when a name is available.
        
        You are AlyAI. The user just said: "\(userInput)".
        Their current focus is: \(currentFocus).
        
        RECENT ACTIVITY & INSIGHTS:
        \(activityHistory)
        
        Generate a short, empathetic response (1-2 sentences) suitable for text-to-speech.
        Refer to their recent insights or actions if relevant to show continuity.
        """
        
        OpenAIService.shared.runAssessment(prompt: prompt) { response in
            DispatchQueue.main.async {
                isThinking = false
                
                // Add ALYAI message to chat history and show transcript
                chatStore.addMessage(response, isUser: false)
                alyaiTranscript = response
                
                Task {
                    await speakResponse(response)
                }
            }
        }
    }
    
    private func speakResponse(_ text: String) async {
        await speechManager.speak(text)
    }
    
    private func stopInteraction() {
        isThinking = false
        conversationStatus = "Tap to speak"
        speechManager.stopSpeaking()
        speechManager.stopRecording()
    }
}

#Preview {
    TalkView(userAnswers: ["current_focus": "anxiety"], chatStore: ChatStore())
}
