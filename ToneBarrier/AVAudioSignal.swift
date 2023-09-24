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
let sampleRate = 44100.0

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node = audio_engine.outputNode
        let audio_format = output_node.outputFormat(forBus: 0)
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            var framePosition: AVAudioFramePosition = ~(1 << (frameCount + 1))
            let inputSignal = (0 ..< Int(frameCount)).map {
                framePosition >>= 1
                ((framePosition & 1) != 0) ? ((framePosition | 1) != 0) ? 1 /* Generate signal sample from first frequency and first half of duration */ : 1 /* Generate signal sample from second frequency and second half of duration */ : 0 /* Generate new frequencies and duration */;
                let x = Float($0)
                return sin((Float(frequency) / Float(frameCount)) * x)
            }
            
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

