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
    private var statusObserver: NSKeyValueObservation?
    
    init(url: URL) {
        print("🎬 Initializing player with URL: \(url)")
        let playerItem = AVPlayerItem(url: url)
        self.player = AVPlayer(playerItem: playerItem)
        setupObservers()
    }
    
    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupObservers() {
        // Observe player item status
        statusObserver = player.currentItem?.observe(\.status, options: [.new, .old]) { [weak self] item, change in
            switch item.status {
            case .readyToPlay:
                print("✅ Video ready to play")
            case .failed:
                print("❌ Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
            case .unknown:
                print("⏳ Video status unknown")
            @unknown default:
                break
            }
        }
        
        // Observe when video finishes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // Observe playback errors
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoPlaybackError),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: player.currentItem
        )
    }
    
    @objc private func videoDidFinish() {
        print("✅ Video completed")
        onComplete?()
    }
    
    @objc private func videoPlaybackError(notification: Notification) {
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            print("❌ Video playback error: \(error.localizedDescription)")
        }
    }
    
    func play() {
        print("▶️ Playing video")
        player.play()
    }
    
    func pause() {
        print("⏸️ Pausing video")
        player.pause()
    }
}
