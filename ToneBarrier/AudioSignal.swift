//
//  AudioSignal.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 4/29/23.
//

import Foundation
import AVFoundation
import AVKit
import SwiftUI
import Combine
import ObjectiveC
import Dispatch
import Accelerate

struct OptionNames {
    static let signal = "signal"
    static let frequency = "freq"
    static let duration = "duration"
    static let output = "output"
    static let amplitude = "amplitude"
}

let frequency = 440.0
let amplitude = 1.0
let duration = 5.0

let twoPi = 2 * Float.pi

let sine = { (phase: Float) -> Float in
    return sin(phase)
}

@objc class AudioSignal: NSObject {
    let audio_engine: AudioEngine = AudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        //        var outCount: UnsafeMutablePointer<UInt32>?
        //        var methodList: UnsafeMutablePointer<Method>? = class_copyMethodList(object_getClass(audio_engine), outCount)
        //        for i in 0..<(outCount?.pointee ?? 0) {
        //            var currentMethod: Method = methodList![Int(i)]
        //            var methodSelector: Selector = method_getName(currentMethod)
        //            debugPrint("\(currentMethod) \(methodSelector)")
        //        }
        //
        let signal: (Float) -> Float = sine
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node = audio_engine.outputNode
        let audio_format = output_node.outputFormat(forBus: 0)
        let frame_count = Float(audio_format.sampleRate) * Float(audio_format.channelCount)
        var currentPhase: Float = 0
        let phaseIncrement = (Float(twoPi) / Float(frame_count)) * Float(frequency)
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            //            debugPrint("audio_source_node_renderer")
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let value = signal(Float(currentPhase)) * Float(amplitude)
                currentPhase += phaseIncrement
                if currentPhase >= twoPi {
                    currentPhase -= twoPi
                }
                if currentPhase < 0.0 {
                    currentPhase += twoPi
                }
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = value
                }
            }
            return noErr
        }
        self.audio_source_node = AVAudioSourceNode(format: audio_format, renderBlock: audio_source_node_renderer)
        
        audio_engine.attach(self.audio_source_node)
        audio_engine.connect(self.audio_source_node, to: main_mixer_node, format: audio_format)
        audio_engine.connect(main_mixer_node, to: output_node, format: audio_format)
    }
    
}

@objc class AudioEngine: AVAudioEngine {
    override func start() throws {
        do {
            try super.start()
        } catch {
            debugPrint("Could not start audio engine: \(error)")
        }
    }
    
    override init() {
        super.init()
    }
    
    
}

//extension AVAudioEngine {
//    struct StaticVars {
//        lazy var token = {0}()
//    }
//
//    public override class func init() {
//
//    }
//
//    public override class func initialize() {
//        dispatch_once(&StaticVars.token) {
//            guard self == UIScrollView.self else {
//                return
//            }
//            // Accessor
//            method_exchangeImplementations(
//                class_getInstanceMethod(self, Selector("swizzledContentOffset")),
//                class_getInstanceMethod(self, Selector("contentOffset"))
//            )
//            // Two-param setter
//            method_exchangeImplementations(
//                class_getInstanceMethod(self, #selector(UIScrollView.setContentOffset(_:animated:))),
//                class_getInstanceMethod(self, #selector(UIScrollView.swizzledSetContentOffset(_:animated:)))
//            )               
//            // One-param setter
//            method_exchangeImplementations(
//                class_getInstanceMethod(self, #selector(UIScrollView.swizzledSetContentOffset(_:))),
//                class_getInstanceMethod(self, Selector("setContentOffset:")))
//        }
//    }
//
//    func swizzledSetContentOffset(inContentOffset: CGPoint, animated: Bool) {
//        print("Some interceding code for the swizzled 2-param setter with \(inContentOffset)")
//        // This is not recursive. The method implementations have been exchanged by runtime. This is the
//        // original setter that will run.
//        swizzledSetContentOffset(inContentOffset, animated: animated)
//    }
//
//
//    func swizzledSetContentOffset(inContentOffset: CGPoint) {
//        print("Some interceding code for the swizzled 1-param setter with \(inContentOffset)")
//        swizzledSetContentOffset(inContentOffset) // not recursive
//    }
//
//
//    var swizzledContentOffset: CGPoint {
//        get {
//            print("Some interceding code for the swizzled accessor: \(swizzledContentOffset)") // false warning
//            return swizzledContentOffset // not recursive, false warning
//        }
//    }
//}

