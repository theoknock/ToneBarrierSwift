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
let amplitude = 1.0
let duration  = 5.0
let tau       = 2.0 * Float.pi


@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node = audio_engine.outputNode
        let audio_format = output_node.outputFormat(forBus: 0)
        let frame_count = Int(Float(audio_format.sampleRate))// * Float(audio_format.channelCount))
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            var inputSignal = (0 ..< Int(frameCount)).map {
                let x = Float($0)
                return sin((Float(frequency) / Float(frameCount)) * x)
            }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for buffer in ablPointer {
                var buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
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

