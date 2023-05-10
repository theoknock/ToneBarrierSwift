//
//  SceneDelegate.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 4/29/23.
//

import UIKit
import AVFoundation

//class AudioSignal: AVAudioSignal {
//    static let sharedAudioSignalGenerator: AudioSignal = {
//        let sharedAudioSignalGenerator = AVAudioSignal() as! AudioSignal
//        return sharedAudioSignalGenerator
//    }()
//}
//
//class AudioSession: AVAudioSession {
//    static let sharedAudioSession: AudioSession = {
//        let sharedAudioSession = AVAudioSession.sharedInstance() as! AudioSession
//        return sharedAudioSession
//    }()
//
//    private override init() {
//        do {
//            audioSessionInterruptionNotificationSetup()
//            try self.setActive(true)
//        } catch {
//            debugPrint("Could not activate audio session: \(error)")
//        }
//    }
//
//    func audioSessionInterruptionNotificationSetup() {
//        do {
//            try self.setCategory(.playback, mode: .default, policy: .longFormAudio)
//            NotificationCenter.default.addObserver(self,
//                                                   selector: #selector(handleInterruption),
//                                                   name: AVAudioSession.interruptionNotification,
//                                                   object: self)
//            NotificationCenter.default.addObserver(self,
//                                                   selector: #selector(restartEngineAfterConfigurationChange(_:)),
//                                                   name: .AVAudioEngineConfigurationChange,
//                                                   object: nil)
//        } catch {
//            print("Failed to set audio session category.")
//        }
//    }
//
//    @objc func handleInterruption(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
//              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
//            return
//        }
//
//        // Switch over the interruption type.
//        switch type {
//
//        case .began:
//            // An interruption began. Update the UI as necessary.
//            debugPrint("Audio session interruption \(type) began")
//
//        case .ended:
//            // An interruption ended. Resume playback, if appropriate.
//            debugPrint("Audio session interruption \(type) ended")
//
//            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
//            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
//            if options.contains(.shouldResume) {
//                // An interruption ended. Resume playback.
//                do {
//                    try audio_session.audio_engine.start()
//                } catch {
//                    debugPrint("Could not start audio engine: \(error)")
//                }
//                debugPrint("Resume playback.")
//            } else {
//                // An interruption ended. Don't resume playback.
//                debugPrint("Don't resume playback.")
//            }
//
//        default: ()
//            self.togglePlaybackControl.isHighlighted = self.audio_signal.audio_engine.isRunning
//        }
//    }
//
//    @objc func restartEngineAfterConfigurationChange(_ notification: Notification) {
//        debugPrint("restartEngineAfterConfigurationChange")
//        do {
//            try self.audio_signal.audio_engine.start()
//        } catch {
//            debugPrint("Could not start audio engine: \(error)")
//        }
//    }
//}



class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var viewController: ViewController?
    
//    let audio_signal:  AudioSignal  = AVAudioSignal() as! AudioSignal
//    let audio_session: AudioSession = AVAudioSession.sharedInstance() as! AudioSession
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        viewController = (window!.rootViewController as! ViewController)
        guard let _ = (scene as? UIWindowScene) else { return }
        
        for userActivity in connectionOptions.userActivities {
            handleUserActivity(userActivity)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        handleUserActivity(userActivity)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    
}

extension SceneDelegate {
    func handleUserActivity(_ userActivity: NSUserActivity) {
        let interaction = userActivity.interaction
        if ((interaction?.intent.isEqual(ToggleToneBarrierIntent())) != nil) {
            viewController?.togglePlaybackControl.isHighlighted = !(viewController?.togglePlaybackControl.isHighlighted)!
        }
    }
}

