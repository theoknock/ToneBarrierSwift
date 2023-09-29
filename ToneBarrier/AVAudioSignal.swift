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
var harmonic  = frequency * (5.0/4.0)
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
        let frame_count     = Float(audio_format.sampleRate) * Float(audio_format.channelCount)
        
        func createSignal(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
//                let x = 0.0 + (((Float($0) - 0.0) * (1.0 - 0.0))) / (Float(~frameCount) - 0.0)
                var x = Float($0) / Float(frameCount)
//                var x: Float = 0.0
//                x = 0.0 + (((x - 0.0) * (1.0 - 0.0))) / (Float(~frameCount) - 0.0)
//                debugPrint("x == \(Float($0))")
                // print x t see if it is counting from 0 to the number of frames or...
                // ...
                return 2.0 * sin(Float(tau) * x * frequency) // sin((Float(frequency) / Float(frameCount)) * x)
            }
            return inputSignal
        }
        
        func multiplySignals(array1: [Float], array2: [Float]) -> [Float] {
            let result = zip(array1, array2).map(*)
            return result
        }
        
        func performCalculation(frameCount: Int, array1: [Float], array2: [Float]) -> [Float] {
            guard array1.count == array2.count else {
                return []
            }
            var result: [Float] = []
            for i in 0..<frameCount {
                result.append(array1[i] * array2[i]) // Change this line to perform your desired operation
            }
            return result
        }

        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            // To-do: Replace with: amplitude • cos((tau •  x) / period)
            let frequencySignal = createSignal(frameCount: Int(frameCount), frequency: Float(frequency))
            let amplitudeSignal = createSignal(frameCount: Int(frameCount), frequency: Float(harmonic))
            let signalSamples   = performCalculation(frameCount: Int(frameCount), array1: frequencySignal, array2: amplitudeSignal)
            
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

