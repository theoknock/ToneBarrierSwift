//
//  ViewController.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 4/29/23.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
import MediaPlayer
import Intents
import IntentsUI

class ViewController: UIViewController, AVRoutePickerViewDelegate {
    
    @IBOutlet weak var waveformSymbol: UIImageView!
    
    @IBOutlet weak var togglePlaybackControl: UIImageView!
    var userInteractionObserver: NSKeyValueObservation?
    
    
    @IBOutlet weak var routePicker: AVRoutePickerView!
    
    var audio_session = AVAudioSession.sharedInstance()
    var audio_signal: AudioSignal = AudioSignal()
    
    lazy var gradient:  CAGradientLayer  = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        let toneBarrierBlue: UIColor = UIColor.init(white: 0.0, alpha: 0.0) //UIColor.init(_colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.0) // UIColor(red: 0.f, green: 0.f, blue: 0.f, alpha: 0.f)
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0, 0.5, 1.0]
        return gradient
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        togglePlaybackControl.layer.shadowColor = UIColor.systemBlue.cgColor
        togglePlaybackControl.layer.shadowRadius = 5.0
        togglePlaybackControl.layer.shadowOpacity = 1.0
        togglePlaybackControl.layer.shadowOffset = CGSize(width: 0, height: 0)
        togglePlaybackControl.layer.masksToBounds = false
        
        gradient.frame = waveformSymbol.bounds
        waveformSymbol.layer.mask = gradient
        
        do {
            setUpNowPlaying()
            setupRemoteTransportControls()
            audioSessionInterruptionNotificationSetup()
            NotificationCenter.default.addObserver(self, selector: #selector(self.restartEngineAfterConfigurationChange(_:)),
                                                   name: .AVAudioEngineConfigurationChange,
                                                   object: nil)
            
            try self.audio_session.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            debugPrint("Could not activate audio session: \(error)")
        }
        
        addSiriButton(to: self.view)
        
        routePicker.delegate = self
        routePicker.backgroundColor = UIColor(named: "clearColor")
        routePicker.tintColor = UIColor.systemBlue
        
        userInteractionObserver = togglePlaybackControl.observe(\.isHighlighted, options: [.new]) { (object, change) in
            debugPrint("Observer: imageView isHighlighted == \(self.togglePlaybackControl.isHighlighted)")
            if change.newValue! {
                do {
                    try self.audio_signal.audio_engine.start()
                } catch {
                    debugPrint("Could not start audio engine: \(error)")
                }
            } else {
                self.audio_signal.audio_engine.stop()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = waveformSymbol.bounds
    }
    
    @IBAction func togglePlaybackControlHandler(_ sender: UITapGestureRecognizer) {
        if let imageView = sender.view as? UIImageView {
            imageView.isHighlighted = !imageView.isHighlighted;
        }
    }
    
    func addSiriButton(to view: UIView) {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        button.shortcut = INShortcut(intent: {
            let intent = ToggleToneBarrierPlaybackIntent()
            intent.suggestedInvocationPhrase = "Activate ToneBarrier"
            return intent
        }())
        button.delegate = self
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: button.topAnchor).isActive = true
    }
    
    @objc func restartEngineAfterConfigurationChange(_ notification: Notification) {
        debugPrint("restartEngineAfterConfigurationChange")
        do {
            try self.audio_signal.audio_engine.start()
        } catch {
            debugPrint("Could not start audio engine: \(error)")
        }
    }
    
    func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // To-Do: Swifter the following:
        // [_nowPlayingInfoCenter setPlaybackState:([_session setActive:(((![_engine isRunning]) && ^ BOOL { return ([_engine startAndReturnError:&error]); }()) || ^ BOOL { [_engine stop]; return ([_engine isRunning]); }()) error:&error] & [_engine isRunning]) ? MPNowPlayingPlaybackStatePlaying : MPNowPlayingPlaybackStateStopped];
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            do {
                try self.audio_signal.audio_engine.start()
                MPNowPlayingInfoCenter.default().playbackState = (self.audio_signal.audio_engine.isRunning) ? .playing : .stopped
            } catch {
                debugPrint("Could not start audio engine: \(error)")
            }
            return (self.audio_signal.audio_engine.isRunning) ? .success : .commandFailed
        }
        
        // Add handler for TogglePlayPause Command
        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
            if (!self.audio_signal.audio_engine.isRunning) {
                do {
                    try self.audio_signal.audio_engine.start()
                } catch {
                    debugPrint("Could not start audio engine: \(error)")
                }
            } else {
                self.audio_signal.audio_engine.pause()
            }
            MPNowPlayingInfoCenter.default().playbackState = (self.audio_signal.audio_engine.isRunning) ? .playing : .paused
            return (!self.audio_signal.audio_engine.isRunning) ? .success : .commandFailed
        }
        
        // Add handler for Stop Command
        commandCenter.stopCommand.addTarget { [unowned self] event in
            self.audio_signal.audio_engine.stop()
            MPNowPlayingInfoCenter.default().playbackState = (self.audio_signal.audio_engine.isRunning) ? .playing : .stopped
            return (!self.audio_signal.audio_engine.isRunning) ? .success : .commandFailed
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.audio_signal.audio_engine.pause()
            MPNowPlayingInfoCenter.default().playbackState = (self.audio_signal.audio_engine.isRunning) ? .playing : .paused
            return (!self.audio_signal.audio_engine.isRunning) ? .success : .commandFailed
        }
    }
    
    func setUpNowPlaying() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "ToneBarrier"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "James Alan Bush"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "The Life of a Demoniac"
        
        let image = UIImage(named: "LockScreenIcon")
        var artwork: MPMediaItemArtwork = MPMediaItemArtwork(boundsSize: image?.size ?? CGSizeZero) { _ in image ?? UIImage(named: "LockScreenIcon")! }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        debugPrint("observeValue")
        if keyPath == "isRunning",
           let running_state = change?[.newKey] {
            print("running_state is: \(running_state)")
        }
    }
    
    func audioSessionInterruptionNotificationSetup() {
        do {
            // Set the audio session category, mode, and options.
            //try audio_session.setCategory(.playback, mode: .moviePlayback, options: [])
            try audio_session.setCategory(.playback,
                                          mode: .default,
                                          policy: .longFormAudio)
        } catch {
            print("Failed to set audio session category.")
        }
        
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance())
        
        
        //        AVAudioEngineConfigurationChange
    }
    
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        // Switch over the interruption type.
        switch type {
            
        case .began:
            // An interruption began. Update the UI as necessary.
            debugPrint("Audio session interruption \(type) began")
            
        case .ended:
            // An interruption ended. Resume playback, if appropriate.
            debugPrint("Audio session interruption \(type) ended")
            
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // An interruption ended. Resume playback.
                do {
                    try self.audio_signal.audio_engine.start()
                } catch {
                    debugPrint("Could not start audio engine: \(error)")
                }
                debugPrint("Resume playback.")
            } else {
                // An interruption ended. Don't resume playback.
                debugPrint("Don't resume playback.")
            }
            
        default: ()
            self.togglePlaybackControl.isHighlighted = self.audio_signal.audio_engine.isRunning
        }
    }
}

extension ViewController: INUIAddVoiceShortcutButtonDelegate, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        if (error != nil) { print("Error: \(String(describing: error))") }
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        present(addVoiceShortcutViewController, animated: true)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        present(editVoiceShortcutViewController, animated: true)
    }
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if (error != nil) { print("Error: \(String(describing: error))") }
        dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
}
