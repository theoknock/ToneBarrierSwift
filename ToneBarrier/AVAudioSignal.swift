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

var root     = 440.0
var harmonic = root * (5.0/4.0)
let tau      = 2.0 * .pi

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node     = audio_engine.outputNode
        let audio_format    = output_node.outputFormat(forBus: 0)
        
        func createSignalSine(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
                let x = Float($0)
                return sin(Float(tau) * (x / Float(frameCount)) * frequency)
            }
            return inputSignal
        }
        
        func createSignalCosine(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
                let x = Float($0)
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
        
        /*
         ----------------------------------------------
         */
        
        func generateFrequencies(rootFrequency: Float, harmonicFactor: Float, length: Int) -> ([Float], [Float]) {
            var rootFreqSamples = [Float](repeating: 0.0, count: length)
            var harmonicFreqSamples = [Float](repeating: 0.0, count: length)
            for i in 0..<length {
                let time = Float(i) / Float(length)
                rootFreqSamples[i] = sin(2 * .pi * rootFrequency * time)
                harmonicFreqSamples[i] = sin(2 * .pi * (rootFrequency * harmonicFactor) * time)
            }
            return (rootFreqSamples, harmonicFreqSamples)
        }
        func combineFrequencies(rootFreqSamples: [Float], harmonicFreqSamples: [Float]) -> [Float] {
            assert(rootFreqSamples.count == harmonicFreqSamples.count, "Input arrays must have equal length")
            var combinedSamples = [Float](repeating: 0.0, count: rootFreqSamples.count)
            for i in 0..<rootFreqSamples.count {
                combinedSamples[i] = (rootFreqSamples[i] + harmonicFreqSamples[i]) / 2.0
            }
            
            return combinedSamples
        }

        /*
         ----------------------------------------------
         */
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            // To-do: Replace with: amplitude • cos((tau •  x) / period)
            let rootFrequency     = createSignalSine(frameCount: Int(frameCount), frequency: Float(root))
            let harmonicFrequency = createSignalCosine(frameCount: Int(frameCount), frequency: Float(harmonic))
            let signalSamples     = mixSignals(frameCount: Int(frameCount), array1: rootFrequency, array2: harmonicFrequency)
            
            /*
             ----------------------------------------------
             */
            let (rootFreqSamples, harmonicFreqSamples) = generateFrequencies(rootFrequency: 440.0, harmonicFactor: 5.0/4.0, length: Int(frameCount))
            let combinedSamples = combineFrequencies(rootFreqSamples: rootFreqSamples, harmonicFreqSamples: harmonicFreqSamples)
            /*
             ----------------------------------------------
             */
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                combinedSamples.withUnsafeBufferPointer { sourceBuffer in
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

