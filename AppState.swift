import SwiftUI

class AppState: ObservableObject {
    @Published var isPlaying: Bool = false {
        didSet {
            MediaPlayerManager.shared.isPlaying = isPlaying
        }
    }

    func setup() {
        // Custom initialization code from didFinishLaunchingWithOptions
    }

    func setupMediaPlayer() {
        MediaPlayerManager.shared.configureAudioSession()
        MediaPlayerManager.shared.setupRemoteCommandCenter()
    }

    func willResignActive() {
        // Handle application becoming inactive
    }

    func didEnterBackground() {
        // Handle application entering background
    }

    func willEnterForeground() {
        // Handle application entering foreground
    }

    func didBecomeActive() {
        // Handle application becoming active
    }

    func willTerminate() {
        // Handle application termination
    }

    func sceneDidDisconnect() {
        // Handle scene disconnection
    }
}
