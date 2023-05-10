//
//  PauseToneBarrierIntentHandler.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 5/9/23.
//

import UIKit
import Intents

class PauseToneBarrierIntentHandler: NSObject, PauseToneBarrierIntentHandling {
        
    var appDelegate: AppDelegate?
    var window: UIWindow?
    var viewController: ViewController?
    
    func handle(intent: PauseToneBarrierIntent, completion: @escaping (PauseToneBarrierIntentResponse) -> Void) {
        appDelegate = (UIApplication.shared.delegate! as! AppDelegate)
        window = appDelegate?.window
        viewController = (window!.rootViewController as! ViewController)
        viewController?.togglePlaybackControl.isHighlighted = !(viewController?.togglePlaybackControl.isHighlighted)!
    }
    
}
