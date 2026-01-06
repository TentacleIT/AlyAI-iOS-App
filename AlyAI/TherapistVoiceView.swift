import SwiftUI
import AVFoundation

struct TherapistVoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var profileManager = UserProfileManager.shared
    @State private var playingPreview: String? = nil
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ZStack {
            Color.alyBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { 
                        stopPreview()
                        dismiss() 
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.alyTextPrimary)
                    }
                    Spacer()
                    Text("Therapist Voice")
                        .font(.alyHeadline)
                        .foregroundColor(.alyTextPrimary)
                    Spacer()
                    // Hidden spacer for balance
                    Image(systemName: "arrow.left").opacity(0).font(.title2)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(TherapistVoiceOption.allCases) { voice in
                            VoiceOptionCard(
                                voice: voice,
                                isSelected: profileManager.voicePreference.voiceId == voice.id,
                                isPlaying: playingPreview == voice.id,
                                onSelect: {
                                    selectVoice(voice)
                                },
                                onPreview: {
                                    previewVoice(voice)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            stopPreview()
        }
    }
    
    private func selectVoice(_ option: TherapistVoiceOption) {
        let preference = TherapistVoicePreference(
            voiceId: option.id,
            gender: option.gender.lowercased(),
            tone: option.tone,
            providerVoiceKey: option.providerVoiceKey,
            lastUpdated: Date()
        )
        Task {
            await profileManager.saveVoicePreference(preference)
        }
    }
    
    private func previewVoice(_ option: TherapistVoiceOption) {
        if playingPreview == option.id {
            stopPreview()
            return
        }
        
        stopPreview() // Stop any current preview
        playingPreview = option.id
        let text = "Hi, I'm \(option.displayName). I'm here to listen and support you."
        
        OpenAIService.shared.generateAudio(text: text, voice: option.providerVoiceKey) { data in
            DispatchQueue.main.async {
                guard let data = data else {
                    self.playingPreview = nil
                    return
                }
                do {
                    self.audioPlayer = try AVAudioPlayer(data: data)
                    self.audioPlayer?.play()
                    
                    // We don't have an easy way to reset state when finished without a delegate, 
                    // but for a preview this is acceptable. The user can toggle it off manually or select another.
                } catch {
                    print("Preview failed")
                    self.playingPreview = nil
                }
            }
        }
    }
    
    private func stopPreview() {
        audioPlayer?.stop()
        playingPreview = nil
    }
}

struct VoiceOptionCard: View {
    let voice: TherapistVoiceOption
    let isSelected: Bool
    let isPlaying: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar / Icon
            ZStack {
                Circle()
                    .fill(isSelected ? Color.alyPrimary.opacity(0.1) : Color.alyCard)
                    .frame(width: 60, height: 60)
                
                Image(systemName: voice.gender == "Female" ? "face.smiling" : "person.fill")
                    .font(.title)
                    .foregroundColor(isSelected ? .alyPrimary : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(voice.displayName)
                    .font(.alyBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.alyTextPrimary)
                
                Text(voice.tone)
                    .font(.caption)
                    .foregroundColor(.alyTextSecondary)
                
                Text(voice.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            // Preview Button
            Button(action: onPreview) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.alyPrimary)
            }
            .padding(.trailing, 8)
            .buttonStyle(PlainButtonStyle()) // Prevent row tap conflict
            
            // Selection Indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.alyPrimary)
            } else {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
            }
        }
        .padding()
        .background(Color.alyCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.alyPrimary : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle()) // Make whole card tappable
        .onTapGesture {
            onSelect()
        }
    }
}
