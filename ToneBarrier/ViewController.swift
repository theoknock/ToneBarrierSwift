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
    
    @IBOutlet var togglePlaybackControlTapHandler: UITapGestureRecognizer!
    let remoteCommandCenter  = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    
    let lockScreenImage = UIImage(named: "Waveform Symbol Lockscreen")
    var lockScreenImageView: UIImageView = UIImageView()
    
    @IBOutlet weak var routePicker: AVRoutePickerView!
    
    var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    var audioSignal: AVAudioSignal = AVAudioSignal()
    
    lazy var gradient: CAGradientLayer  = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        let toneBarrierBlue: UIColor = UIColor.init(white: 0.0, alpha: 0.0)
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        return gradient
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradient.frame = waveformSymbol.bounds
        waveformSymbol.layer.mask = gradient
        
        do {
            try audioSession.setCategory(.playback,
                                         mode: .default,
                                         policy: .longFormAudio)
            try self.audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }
        
        setUpNowPlayingInfoCenter()
        setupRemoteCommandCenter()
        setupAudioSessionInterruptionNotification()
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.restartEngineAfterConfigurationChange(_:)),
        //                                               name: .AVAudioEngineConfigurationChange,
        //                                               object: nil)
        
        
        addSiriButton(to: self.view)
        
        routePicker.delegate = self
        routePicker.backgroundColor = UIColor(named: "clearColor")
        routePicker.tintColor = UIColor.systemBlue
        
//        userInteractionObserver = togglePlaybackControl.observe(\.isHighlighted, options: [.new]) { [self] (object, change) in
//            print("Observer: imageView isHighlighted == \(self.togglePlaybackControl.isHighlighted)")
//            if change.newValue! {
//                audio()
//            }
//        }
    }
    
    func audio() -> Bool {
        do {
            if !(audioSignal.audio_engine.isRunning) {
                try audioSignal.audio_engine.start()
            } else {
                audioSignal.audio_engine.pause()
            }
        } catch {
            debugPrint("Could not start audio engine: \(error)")
        }
        return audioSignal.audio_engine.isRunning
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = waveformSymbol.bounds
    }
    
    @IBAction func togglePlaybackControlHandler(_ sender: UITapGestureRecognizer) {
        if let imageView = sender.view as? UIImageView {
            imageView.isHighlighted = audio()
        }
    }
    
    func addSiriButton(to view: UIView) {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        button.shortcut = INShortcut(intent: {
            let intent = ToggleToneBarrierIntent()
            intent.suggestedInvocationPhrase = "Toggle ToneBarrier"
            return intent
        }())
        button.delegate = self
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        view.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
        view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: button.topAnchor).isActive = true
    }
    
    func setupRemoteCommandCenter() {
        
        
        // To-Do: Swifter the following:
        //        playingInfoCenter.playbackState =
        //        audio_session.setActive(!self.audio_signal.audio_engine.isRunning)) // && {
        //        do {
        //            try self.audio_signal.audio_engine.start()
        //            playingInfoCenter.playbackState = (self.audio_signal.audio_engine.isRunning) ? .playing : .stopped
        //        } catch {
        //            debugPrint("Could not start audio engine: \(error)")
        //        }
        //}) || ^ BOOL { [_engine stop]; return ([_engine isRunning]); }()) error:&error] & [_engine isRunning]) ? MPNowPlayingPlaybackStatePlaying : MPNowPlayingPlaybackStateStopped];
        
        // Add handler for Play Command
//        remoteCommandCenter.playCommand.addTarget { [self] event in
//            do {
//                try audioSignal.audio_engine.start()
//            } catch {
//                debugPrint("Could not start audio engine: \(error)")
//            }
//            //            nowPlayingInfoCenter.playbackState = .playing//(audioSignal.audio_engine.isRunning) ? .playing : .stopped
//            return (audioSignal.audio_engine.isRunning) ? .success : .commandFailed
//        }
        
        // Add handler for TogglePlayPause Command
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [self] event in
            togglePlaybackControlHandler(togglePlaybackControlTapHandler)
            return .success
        }
        
        // Add handler for Stop Command
//        remoteCommandCenter.stopCommand.addTarget { [self] event in
//            audioSignal.audio_engine.stop()
//            //            nowPlayingInfoCenter.playbackState = .stopped//(audioSignal.audio_engine.isRunning) ? .playing : .stopped
//            return (!audioSignal.audio_engine.isRunning) ? .success : .commandFailed
//        }
        
        // Add handler for stop Command
//        remoteCommandCenter.pauseCommand.addTarget { [self] event in
//            audioSignal.audio_engine.stop()
//            //            nowPlayingInfoCenter.playbackState = .paused//(audioSignal.audio_engine.isRunning) ? .playing : .paused
//            return (!audioSignal.audio_engine.isRunning) ? .success : .commandFailed
//        }
    }
    
    func setUpNowPlayingInfoCenter() {
        var now_playinfo_info = [String : Any]()
        now_playinfo_info[MPMediaItemPropertyTitle] = "ToneBarrier"
        now_playinfo_info[MPMediaItemPropertyArtist] = "James Alan Bush"
        now_playinfo_info[MPMediaItemPropertyAlbumTitle] = "The Life of a Demoniac"
        
        DispatchQueue.main.async { [self] in
            lockScreenImageView = UIImageView(image: lockScreenImage)
            let artwork: MPMediaItemArtwork = MPMediaItemArtwork(boundsSize: lockScreenImageView.image?.size ?? CGSizeZero, requestHandler: { [self] _ in lockScreenImageView.image! })
            now_playinfo_info[MPMediaItemPropertyArtwork] = artwork
        }
    
        nowPlayingInfoCenter.nowPlayingInfo = now_playinfo_info
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        debugPrint("observeValue")
        if keyPath == "isRunning",
           let running_state = change?[.newKey] {
            print("running_state is: \(running_state)")
        } else {
            print("keypath: \(String(describing: keyPath))")
            print("change.newKey: \(String(describing: change?[.newKey]))")
        }
    }
    
    func setupAudioSessionInterruptionNotification() {
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
        
        debugPrint("Audio session interruption \(type)")
        
        
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
            //        if options.contains(.shouldResume) {
            //            // An interruption ended. Resume playback.
            //            do {
            //                try self.audio_signal.audio_engine.start()
            //            } catch {
            //                debugPrint("Could not start audio engine: \(error)")
            //            }
            //            debugPrint("Resume playback.")
            //        } else {
            //            // An interruption ended. Don't resume playback.
            //            debugPrint("Don't resume playback.")
            //        }
            
        default: ()
            debugPrint("Audio session interruption \(type)")
            //        self.togglePlaybackControl.isHighlighted = self.audio_signal.audio_engine.isRunning
        }
    }
    
    @objc func restartEngineAfterConfigurationChange(_ notification: Notification) {
        debugPrint("restartEngineAfterConfigurationChange")
        //    do {
        //        try self.audio_signal.audio_engine.start()
        //    } catch {
        //        debugPrint("Could not start audio engine: \(error)")
        //    }
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

extension CAGradientLayer {
    func setColors(_ newColors: [CGColor],
                   animated: Bool = true,
                   withDuration duration: TimeInterval = 0,
                   timingFunctionName name: CAMediaTimingFunctionName? = nil) {
        
        if !animated {
            self.colors = newColors
            return
        }
        
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.fromValue = colors
        colorAnimation.toValue = newColors
        colorAnimation.duration = duration
        colorAnimation.isRemovedOnCompletion = false
        colorAnimation.fillMode = CAMediaTimingFillMode.forwards
        colorAnimation.timingFunction = CAMediaTimingFunction(name: name ?? .linear)
        
        add(colorAnimation, forKey: "colorsChangeAnimation")
    }
}
