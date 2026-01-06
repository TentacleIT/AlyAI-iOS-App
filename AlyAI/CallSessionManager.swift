import Foundation
import AVFoundation
import Speech
import SwiftUI
import Combine

enum CallState: Equatable, Sendable {
    case idle
    case listening
    case processing
    case speaking
    case ending
    case error(String)
}

class CallSessionManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate, AVAudioPlayerDelegate {
    
    // MARK: - Published Properties
    @Published var state: CallState = .idle
    @Published var transcript: String = "" // Current user speech
    @Published var aiResponse: String = "" // Current AI response
    @Published var audioLevel: Float = 0.0 // For visualization (0.0 to 1.0)
    @Published var callDuration: TimeInterval = 0
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // REPLACED: AVSpeechSynthesizer with AVAudioPlayer for OpenAI TTS
    private var audioPlayer: AVAudioPlayer?
    
    private var silenceTimer: Timer?
    private let silenceThreshold: TimeInterval = 1.5 // Time to wait after speech stops
    private var callTimer: Timer?
    
    private var isInterrupted = false
    private var isGreeting: Bool = false
    var context: [String: Any] = [:] // Context for AI
    private var currentVoice: TherapistVoicePreference = .default
    
    // MARK: - Initialization
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestPermissions()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            // Handle authorization status if needed
        }
    }
    
    // MARK: - Session Management
    
    func startSession() {
        print("Starting Call Session...")
        // Load voice preference
        self.currentVoice = UserProfileManager.shared.voicePreference
        setupAudioSession()
        startCallTimer()
        speakGreeting()
    }
    
    private func speakGreeting() {
        isGreeting = true
        let nameRaw = context["name"] as? String
        let name = (nameRaw?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? nameRaw!.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        
        let greeting = name.isEmpty ? "Hi, this is AlyAI. I’m here with you." : "Hi \(name), this is AlyAI. I’m here with you."
        speakResponse(greeting)
    }
    
    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            stopListening()
            // Keep state as listening visually if we were listening, or handle in UI
        } else {
            if state == .listening || state == .idle {
                startListening()
            }
        }
    }
    
    func toggleSpeaker() {
        isSpeakerOn.toggle()
        let session = AVAudioSession.sharedInstance()
        do {
            if isSpeakerOn {
                try session.overrideOutputAudioPort(.speaker)
            } else {
                try session.overrideOutputAudioPort(.none)
            }
        } catch {
            print("Failed to toggle speaker: \(error)")
        }
    }
    
    func endSession() {
        print("Ending Call Session...")
        state = .ending
        stopListening()
        stopSpeaking()
        stopCallTimer()
        deactivateAudioSession()
        state = .idle
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session: \(error)")
            state = .error("Audio Error")
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func startCallTimer() {
        callDuration = 0
        callTimer?.invalidate()
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }
    
    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }
    
    // MARK: - Speech Recognition (Listening)
    
    private func startListening() {
        guard state != .ending else { return }
        if isMuted { return }
        
        // Ensure cleanup
        stopListening()
        
        // Reset transcript for new turn
        transcript = ""
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            state = .error("Speech recognition unavailable")
            return
        }
        
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Audio Level Tap
            inputNode.removeTap(onBus: 0) // Remove any existing
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
                guard let self = self else { return }
                self.recognitionRequest?.append(buffer)
                
                // Calculate audio level for visualization
                let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(buffer.format.channelCount))
                if let channelData = channels.first {
                    let frameLength = Int(buffer.frameLength)
                    let samples = UnsafeBufferPointer(start: channelData, count: frameLength)
                    var sum: Float = 0
                    for sample in samples {
                        sum += abs(sample)
                    }
                    let average = sum / Float(frameLength)
                    DispatchQueue.main.async {
                        self.audioLevel = average * 5 // Amplify a bit for visual
                    }
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            state = .listening
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let newTranscript = result.bestTranscription.formattedString
                    // If transcript changed, user is speaking
                    if newTranscript != self.transcript {
                        self.transcript = newTranscript
                        self.resetSilenceTimer()
                        
                        // If we were speaking (interruption), stop speaking
                        if self.audioPlayer?.isPlaying == true {
                           self.stopSpeaking()
                        }
                    }
                }
                
                if let error = error {
                    print("Recognition error: \(error)")
                    // Determine if we should restart or fail
                    self.stopListening()
                    if self.state != .ending {
                        // Restart listening if it wasn't intentional stop
                    }
                }
            }
            
        } catch {
            print("Listening failed: \(error)")
            state = .error("Listening failed")
        }
    }
    
    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        silenceTimer?.invalidate()
    }
    
    // MARK: - Silence Detection
    
    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            self?.didDetectSilence()
        }
    }
    
    @MainActor private func didDetectSilence() {
        guard !transcript.isEmpty else {
            // User hasn't said anything significant yet, or just noise.
            // Keep listening.
            return
        }
        
        print("Silence detected. Processing input: \(transcript)")
        processUserSpeech()
    }
    
    // MARK: - Processing & AI
    
    @MainActor private func processUserSpeech() {
        stopListening() // Pause listening while thinking/speaking to avoid picking up self
        state = .processing
        
        let userText = transcript
        
        // Build context string
        let currentFocus = context["current_focus"] as? String ?? "wellness"
        let nameRaw = context["name"] as? String
        let name = (nameRaw?.isEmpty == false) ? nameRaw! : "Friend"
        
        // Gender-aware Context: Inject Cycle Data if Female
        var cycleContext = ""
        if let gender = context["gender"] as? String, gender.caseInsensitiveCompare("female") == .orderedSame {
            cycleContext = "\n" + CycleManager.shared.getCycleContextForAI()
        }
        
        let activityHistory = ActivityManager.shared.getHistoryForOpenAI()
        
        // Dynamic Voice Persona
        let voiceTone = currentVoice.tone
        let voiceGender = currentVoice.gender
        
        let prompt = """
        You are a \(voiceTone) \(voiceGender) therapist speaking to a client on a phone call.
        Your voice should sound warm, human, and emotionally present.
        Speak naturally with gentle pauses.
        Avoid monotone or robotic delivery.
        Match the user’s emotional state with empathy and reassurance.
        Do not sound like an assistant or machine.
        
        The user’s name is \(name).
        Address the user by name naturally and warmly.
        
        You are AlyAI, a compassionate life companion. You are in a live voice call with \(name).
        Their current focus is: \(currentFocus).\(cycleContext)
        
        RECENT ACTIVITY & INSIGHTS:
        \(activityHistory)
        
        The user just said: "\(userText)".
        
        Instructions:
        - Respond naturally as if on a phone call.
        - Incorporate knowledge of their recent insights or actions if relevant (e.g. "That meditation yesterday...").
        - Be concise (1-3 sentences).
        - Be empathetic and supportive.
        - Use affirmations like "I hear you..." or "You're not alone in this."
        - Do NOT use emojis or formatting (asterisks, etc) as this is for Text-to-Speech.
        """
        
        OpenAIService.shared.runAssessment(prompt: prompt) { [weak self] response in
            DispatchQueue.main.async {
                self?.aiResponse = response
                self?.speakResponse(response)
            }
        }
    }
    
    // MARK: - TTS (Speaking)
    
    private func speakResponse(_ text: String) {
        state = .speaking
        
        // Use OpenAI Native Audio Generation
        OpenAIService.shared.generateAudio(text: text, voice: currentVoice.providerVoiceKey) { [weak self] audioData in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                guard let data = audioData else {
                    print("❌ Failed to generate audio. Falling back to listening.")
                    self.startListening()
                    return
                }
                
                self.playAudio(data: data)
            }
        }
    }
    
    private func playAudio(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("❌ Audio playback failed: \(error)")
            startListening()
        }
    }
    
    private func stopSpeaking() {
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("AI finished speaking (OpenAI TTS)")
        
        if isGreeting {
            isGreeting = false
        }
        
        if state != .ending {
            // Resume listening
            startListening()
        }
    }
}
