import Foundation
import AVFoundation
import Speech
import SwiftUI
import Combine

@MainActor
class SpeechManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    // MARK: - Properties
    
    // STT
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // TTS
    private var audioPlayer: AVAudioPlayer?
    
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var permissionGranted = false
    @Published var isSpeaking = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        speechRecognizer?.delegate = self
        requestPermissions()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.permissionGranted = authStatus == .authorized
            }
        }
    }
    
    // MARK: - Audio Session Management
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if audioSession.category != .playAndRecord {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            }
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio setup failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Speech Recognition (STT)
    
    func startRecording() {
        if isRecording { stopRecording() }
        transcript = ""
        errorMessage = nil
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available."
            return
        }
        
        do {
            setupAudioSession()
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Unable to create recognition request."
                return
            }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
            
            isRecording = true
            
        } catch {
            errorMessage = "Recording failed: \(error.localizedDescription)"
            stopRecording()
        }
    }
    
    func stopRecording() {
        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        audioEngine.reset()
        isRecording = false
    }
    
    // MARK: - Text-to-Speech (TTS) via OpenAI
    
    func speak(_ text: String) async {
        stopSpeaking()
        
        guard !text.isEmpty else { return }
        
        setupAudioSession()
        
        // Load API Key from Info.plist
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, !apiKey.isEmpty else {
            errorMessage = "OpenAI API Key not found in plist."
            return
        }
        
        isSpeaking = true
        
        do {
            let url = URL(string: "https://api.openai.com/v1/audio/speech")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Build JSON body for a human-like therapist voice
            let body: [String: Any] = [
                "model": "gpt-4o-mini-tts",
                "voice": "alloy", // professional, human-like voice
                "input": text
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "TTS request failed."
                isSpeaking = false
                return
            }
            
            // Save audio to temp file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("tts.mp3")
            try data.write(to: tempURL)
            
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            // Monitor completion
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 1.0)) { [weak self] in
                self?.isSpeaking = false
            }
            
        } catch {
            errorMessage = "TTS error: \(error.localizedDescription)"
            isSpeaking = false
        }
    }
    
    func stopSpeaking() {
        audioPlayer?.stop()
        isSpeaking = false
    }
}
