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

var frequency = 220.0
var harmonic  = frequency * (5.0/4.0)

var frame: AVAudioFramePosition = 0
var frame_t: UnsafeMutablePointer<AVAudioFramePosition> = UnsafeMutablePointer(&frame)
var n_time: simd_double1 = .zero
var n_time_t: UnsafeMutablePointer<simd_double1> = UnsafeMutablePointer(&n_time)

//var normalized_times_ref: UnsafeMutablePointer<simd_double1>? = nil;
//var normalized_times: (AVAudioFrameCount) -> UnsafeMutablePointer<simd_double1>? = { (frame_count) in
//    var normalized_time = [simd_double1](repeating: .zero, count: Int(frame_count))
//    normalized_times_ref = UnsafeMutablePointer(mutating: normalized_time)
//    
//    for frame in stride(from: frame_t.pointee, to: frame_count, by: 1) {
//        n_time_t.pointee = 0.0 + (((frame - 0.0) * (1.0 - 0.0))) / (Double(~frame_count) - 0.0)
//        normalized_times_ref?.advanced(by: Int(frame)).pointee = n_time_t.pointee
//    }
//    
//    return normalized_times_ref
//}

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node = audio_engine.outputNode
        let audio_format = output_node.outputFormat(forBus: 0)
//        normalized_times(AVAudioFrameCount(audio_format.sampleRate))  
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
//            let normalizedTime = (0 ..< Int(frameCount)).map {
//                let x = 0.0 + (((Float($0) - 0.0) * (1.0 - 0.0))) / (Double(~frameCount) - 0.0) // Float($0)
//                return sin((Float(frequency) / Float(frameCount)) * x)
//            }
            
            // To-do: Replace with: amplitude • cos((tau •  x) / period)
            let inputSignal = (0 ..< Int(frameCount)).map {
                let x = Float($0)
                return sin((Float(frequency) / Float(frameCount)) * x)
            }
            
            /*
                             ((2.0 * M_PI) / frameCount) * frequency;
                             ((2.0 * M_PI) / frameCount) * harmonic;
                             let a = sin((Float(frequency) / Float(frameCount)) * x)
                             let b = sin((Float(harmonic)  / Float(frameCount)) * x)
                             return (2.0 * (sin(a + b) * cos(a - b))) / 2.0
             */
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                inputSignal.withUnsafeBufferPointer { sourceBuffer in
                    buf.baseAddress!.initialize(from: sourceBuffer.baseAddress!, count: inputSignal.count)
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

