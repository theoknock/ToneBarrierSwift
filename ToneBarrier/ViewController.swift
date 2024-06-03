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
    
    var was_running: Bool!
    
    lazy var gradient: CAGradientLayer  = {
        let gradient = CAGradientLayer()
        gradient.type = .axial
        let clearer: UIColor = UIColor.init(white: 0.0, alpha: 0.1)
        gradient.colors = [
            clearer.cgColor,
            UIColor.black.cgColor,
            clearer.cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        return gradient
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradient.frame = waveformSymbol.bounds
        waveformSymbol.layer.mask = gradient
        
        do {
            try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category.")
        }
        
        setUpNowPlayingInfoCenter()
        setupRemoteCommandCenter()
        setupAudioSessionInterruptionNotification()
        
        addSiriButton(to: self.view)
        
        routePicker.delegate = self
        routePicker.backgroundColor = UIColor(named: "clearColor")
        routePicker.tintColor = UIColor(named: "systemBlueColor")
    }
    
    func audio() -> Bool {
        do {
            if !(audioSignal.audio_engine.isRunning) {
                try audioSignal.audio_engine.start()
            } else {
                audioSignal.audio_engine.pause()
            }
        } catch let error as NSError {
            debugPrint("\(error.localizedDescription)")
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
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [self] event in
            togglePlaybackControlHandler(togglePlaybackControlTapHandler)
            return .success
        }
    }
    
    func setUpNowPlayingInfoCenter() {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "ToneBarrier"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "James Alan Bush"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "The Life of a Demoniac"
        
        let image: UIImage = UIImage.init(systemName: "waveform.path")! //UIImage(named: "LockScreenIcon")
        let artwork: MPMediaItemArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
//        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
//    func setUpNowPlayingInfoCenter() {
//        var now_playinfo_info = [String : Any]()
//        now_playinfo_info[MPMediaItemPropertyTitle] = "ToneBarrier"
//        now_playinfo_info[MPMediaItemPropertyArtist] = "James Alan Bush"
//        now_playinfo_info[MPMediaItemPropertyAlbumTitle] = "The Life of a Demoniac"
//        
//        DispatchQueue.main.async { [self] in
//            lockScreenImageView = UIImageView(image: lockScreenImage)
//            let artwork: MPMediaItemArtwork = MPMediaItemArtwork(boundsSize: lockScreenImageView.image?.size ?? CGSizeZero, requestHandler: { [self] _ in lockScreenImageView.image! })
//            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
//        }
//        
////        nowPlayingInfoCenter.nowPlayingInfo = now_playinfo_info
//    }
    
    func setupAudioSessionInterruptionNotification() {
        let center = NotificationCenter.default
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [self] notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                was_running = audioSignal.audio_engine.isRunning
                if (was_running) {
                    togglePlaybackControl.isHighlighted = false
                    
                }
            case .ended:
                if (was_running) {
                    togglePlaybackControl.isHighlighted = audio()
                }
            @unknown default:
                break
            }
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
