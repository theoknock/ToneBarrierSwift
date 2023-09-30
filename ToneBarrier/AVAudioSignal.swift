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

var root = 440.0
var harmonic  = 550.0 //frequency * (5.0/4.0)
let tau = 2.0 * .pi

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node     = audio_engine.outputNode
        let audio_format    = output_node.outputFormat(forBus: 0)
//        let frame_count     = Float(audio_format.sampleRate) * Float(audio_format.channelCount)
        
        func createSignalSine(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
                let x = Float($0)
//                debugPrint("x == \(x)")
                return sin(Float(tau) * (x / Float(frameCount)) * frequency) // sin((Float(frequency) / Float(frameCount)) * x)
            }
            return inputSignal
        }
        
        func createSignalCosine(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
                let x = Float($0)
//                debugPrint("x == \(x)")
                return cos(Float(tau) * (x / Float(frameCount)) * frequency)
            }
            return inputSignal
        }
        
        func mixSignals(frameCount: Int, array1: [Float], array2: [Float]) -> [Float] {
            let result = (0 ..< frameCount).map {
                let x = $0
                return 0.5 * (array1[x] + array2[x])
            }
            return result
        }

        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            // To-do: Replace with: amplitude • cos((tau •  x) / period)
            let rootFrequency     = createSignalSine(frameCount: Int(frameCount), frequency: Float(root))
            let harmonicFrequency = createSignalCosine(frameCount: Int(frameCount), frequency: Float(harmonic))
            let signalSamples     = mixSignals(frameCount: Int(frameCount), array1: rootFrequency, array2: harmonicFrequency)
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                signalSamples.withUnsafeBufferPointer { sourceBuffer in
                    buf.baseAddress!.initialize(from: sourceBuffer.baseAddress!, count: Int(frameCount))
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

