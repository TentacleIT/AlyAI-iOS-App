import SwiftUI
import AVKit
import Combine

// MARK: - Video Player View with AVPlayer

struct VideoPlayerView: View {
    let videoURL: URL
    let onComplete: () -> Void
    
    @StateObject private var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(videoURL: URL, onComplete: @escaping () -> Void) {
        self.videoURL = videoURL
        self.onComplete = onComplete
        _playerViewModel = StateObject(wrappedValue: PlayerViewModel(url: videoURL))
    }
    
    var body: some View {
        ZStack {
            // Video Player
            VideoPlayer(player: playerViewModel.player)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    playerViewModel.play()
                    playerViewModel.onComplete = onComplete
                }
                .onDisappear {
                    playerViewModel.pause()
                }
        }
    }
}

// MARK: - Player View Model

class PlayerViewModel: ObservableObject {
    let player: AVPlayer
    var onComplete: (() -> Void)?
    private var timeObserver: Any?
    
    init(url: URL) {
        self.player = AVPlayer(url: url)
        setupNotifications()
    }
    
    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        // Observe when video finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }
    
    @objc private func videoDidFinish() {
        print("✅ Video completed")
        onComplete?()
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
}
