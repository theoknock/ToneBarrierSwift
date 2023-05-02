//
//  ToggleToneBarrierIntentHandler.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 4/29/23.
//

import UIKit
import Intents

class ToggleToneBarrierPlaybackIntentHandler: NSObject, ToggleToneBarrierPlaybackIntentHandling {
        
    var appDelegate: AppDelegate?
    var window: UIWindow?
    var viewController: ViewController?
    
    func handle(intent: ToggleToneBarrierPlaybackIntent, completion: @escaping (ToggleToneBarrierPlaybackIntentResponse) -> Void) {
        appDelegate = (UIApplication.shared.delegate! as! AppDelegate)
        window = appDelegate?.window
        viewController = (window!.rootViewController as! ViewController)
        viewController?.togglePlaybackControl.isHighlighted = !(viewController?.togglePlaybackControl.isHighlighted)!
    }
    
}
