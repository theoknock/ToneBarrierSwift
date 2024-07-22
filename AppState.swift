import SwiftUI
import AVFoundation
import MediaPlayer

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isPlaying: Bool = false {
        didSet {
            MediaPlayerManager.shared.isPlaying = isPlaying
        }
    }
    
    var wasRunning: Bool = false
    let remoteCommandCenter = MPRemoteCommandCenter.shared()

    private init() {
        setupRemoteCommandCenter()
        setupAudioSessionInterruptionNotification()
        setUpNowPlayingInfoCenter()
    }
    
    func setup() {
        // Custom initialization code from didFinishLaunchingWithOptions
    }

    func setupMediaPlayer() {
        MediaPlayerManager.shared.configureAudioSession()
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

    func setupRemoteCommandCenter() {
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.isPlaying.toggle()
            return .success
        }
    }
    
    func setUpNowPlayingInfoCenter() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "ToneBarrier"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "James Alan Bush"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "The Life of a Demoniac"
        
        let image = UIImage(systemName: "waveform.path") ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func setupAudioSessionInterruptionNotification() {
        let center = NotificationCenter.default
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                self?.wasRunning = MediaPlayerManager.shared.isPlaying
                if self?.wasRunning == true {
                    self?.isPlaying = false
                }
            case .ended:
                if self?.wasRunning == true {
                    self?.isPlaying = true
                }
            @unknown default:
                break
            }
        }
    }
}
