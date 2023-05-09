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

var frequency = 440.0
var trill     = 6.0
let amplitude = 1.0
let duration  = 5.0
let twoPi     = 2.0 * Float.pi

let sine = { (phase: Float) -> Float in
    return sin(phase)
}

let trill_interval = { (frequency: Float) -> Float in
    return ((frequency / (3000.00 - 200.00) * (18.00 - 2.00)) + 2.00)
}

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        
        let signal: (Float) -> Float = sine
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node = audio_engine.outputNode
        let audio_format = output_node.outputFormat(forBus: 0)
        let frame_count = Int(Float(audio_format.sampleRate) * Float(audio_format.channelCount))
        var currentPhase: Float = 0
        var phaseIncrement = (Float(twoPi) / Float(frame_count)) * Float(frequency)
        
        var currentPhase_trill: Float = 0
        var phaseIncrement_trill = (Float(twoPi) / Float(frame_count)) * Float(trill_interval(Float(frequency)))
        
        
        var frame_position: Int = 0;
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                frame_position += (frame_position == frame_count) ? {
                    frequency = frequency + 100
                    phaseIncrement = (Float(twoPi) / Float(frame_count)) * Float(frequency)
                    phaseIncrement_trill = (Float(twoPi) / Float(frame_count)) * Float(trill_interval(Float(frequency)))
                    return -frame_count }() : 1
                let value = (signal(Float(currentPhase)) * signal(Float(currentPhase_trill))) * Float(amplitude)
                currentPhase += phaseIncrement
                if currentPhase >= twoPi {
                    currentPhase -= twoPi
                }
                if currentPhase < 0.0 {
                    currentPhase += twoPi
                }
                currentPhase_trill += phaseIncrement_trill
                if currentPhase_trill >= twoPi {
                    currentPhase_trill -= twoPi
                }
                if currentPhase_trill < 0.0 {
                    currentPhase_trill += twoPi
                }
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = value
                }
            }
            return noErr
        }
        
        //    self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
        //        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        //        for frame in 0..<Int(frameCount) {
        //            let value = signal(Float(currentPhase)) * Float(amplitude)
        //            currentPhase += phaseIncrement
        //            if currentPhase >= twoPi {
        //                currentPhase -= twoPi
        //            }
        //            if currentPhase < 0.0 {
        //                currentPhase += twoPi
        //            }
        //            for buffer in ablPointer {
        //                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
        //                buf[frame] = value
        //            }
        //        }
        //        return noErr
        //    }
        
        self.audio_source_node = AVAudioSourceNode(format: audio_format, renderBlock: audio_source_node_renderer)
        
        audio_engine.attach(self.audio_source_node)
        audio_engine.connect(self.audio_source_node, to: main_mixer_node, format: audio_format)
        audio_engine.connect(main_mixer_node, to: output_node, format: audio_format)
    }
    
}

//typedef NS_ENUM(NSUInteger, Trill) {
//    TonalTrillUnsigned,
//    TonalTrillInverse
//};

//+ (double(^)(double, double))Frequency
//{
//    return ^double(double time, double frequency)
//    {
//        return pow(sinf(M_PI * time * frequency), 2.0);
//    };
//}

//+ (double(^)(double))TrillInterval
//{
//    return ^double(double frequency)
//    {
//        return ((frequency / (max_frequency - min_frequency) * (max_trill_interval - min_trill_interval)) + min_trill_interval);
//    };
//}

//+ (double(^)(double, double))Trill
//{
//    return ^double(double time, double trill)
//    {
//        return pow(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5, 4.0);
//    };
//}

//+ (double(^)(double, double))TrillInverse
//{
//    return ^double(double time, double trill)
//    {
//        return pow(-(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5) + 1.0, 4.0);
//    };
//}

//typedef double (^Normalize)(double, double, double);
//Normalize normalize = ^double(double min, double max, double value)
//{
//    double result = (value - min) / (max - min);
//    
//    return result;
//};
//
//typedef double (^FrequencySample)(double, double, double);
//FrequencySample sample_frequency = ^(double time, double frequency, double trill)
//{
//    double result = sinf(M_PI * time * frequency) * ^double
//                                        (double time, double trill) {
//        return (sinf(M_PI_PI * time * trill) / 2); //((frequency / (2000.0 - 400.0) * (12.0 - 4.0)) + 4.0);
//    } (time, trill);
//    
//    return result;
//};
//
//typedef double (^AmplitudeSample)(double, double, double);
//AmplitudeSample sample_amplitude = ^(double time, double gain, double tremolo)
//{
//    double result =  sinf((M_PI_PI * time * tremolo) / 2) * (time * gain);
//    
//    return result;
//};


//@objc class AudioEngine: AVAudioEngine {
//    override func start() throws {
//        do {
//            try super.start()
//        } catch {
//            debugPrint("Could not start audio engine: \(error)")
//        }
//    }
//
//    override init() {
//        super.init()
//    }
//
//
//}

//extension AVAudioEngine {
//    struct StaticVars {
//        lazy var token = {0}()
//    }
//
//    public override class func init() {
////        var outCount: UnsafeMutablePointer<UInt32>?
//        var methodList: UnsafeMutablePointer<Method>? = class_copyMethodList(object_getClass(audio_engine), outCount)
//        for i in 0..<(outCount?.pointee ?? 0) {
//            var currentMethod: Method = methodList![Int(i)]
//            var methodSelector: Selector = method_getName(currentMethod)
//            debugPrint("\(currentMethod) \(methodSelector)")
//        }
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

