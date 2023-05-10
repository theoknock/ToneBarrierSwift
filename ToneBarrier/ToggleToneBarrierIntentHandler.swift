//
//  PlayToneBarrierIntentHandler.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 4/29/23.
//

import UIKit
import Intents

class ToggleToneBarrierIntentHandler: NSObject, ToggleToneBarrierIntentHandling {
        
    var appDelegate: AppDelegate?
    var window: UIWindow?
    var viewController: ViewController?
    
    func handle(intent: ToggleToneBarrierIntent, completion: @escaping (ToggleToneBarrierIntentResponse) -> Void) {
        appDelegate = (UIApplication.shared.delegate! as! AppDelegate)
        window = appDelegate?.window
        viewController = (window!.rootViewController as! ViewController)
        viewController?.togglePlaybackControl.isHighlighted = !(viewController?.togglePlaybackControl.isHighlighted)!
    }
    
}
