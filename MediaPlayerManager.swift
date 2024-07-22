import MediaPlayer
import AVFoundation
import SwiftUI

class MediaPlayerManager: ObservableObject {
    static let shared = MediaPlayerManager()
    
    private let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()

    @Published var isPlaying: Bool = false {
        didSet {
            if isPlaying {
                startPlaying()
            } else {
                pausePlaying()
            }
        }
    }

    private init() {
        setupRemoteCommandCenter()
        configureAudioSession()
    }

    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func setupRemoteCommandCenter() {
        remoteCommandCenter.playCommand.addTarget { [weak self] event in
            self?.isPlaying = true
            return .success
        }
        remoteCommandCenter.pauseCommand.addTarget { [weak self] event in
            self?.isPlaying = false
            return .success
        }
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.isPlaying.toggle()
            return .success
        }
    }

    private func startPlaying() {
        updateNowPlayingInfo(isPlaying: true)
        // Start your audio playback here
    }

    private func pausePlaying() {
        updateNowPlayingInfo(isPlaying: false)
        // Pause your audio playback here
    }

    private func updateNowPlayingInfo(isPlaying: Bool) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Your Audio Title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Your Artist Name"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 300
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
