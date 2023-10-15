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

let root: Float     = Float(440.0)
let harmonic: Float = Float(880.0) //root * (5.0/4.0))
let tau: Float      = Float(2.0 * Float.pi)
var frame: AVAudioFramePosition = Int64.zero
var frame_t: UnsafeMutablePointer<AVAudioFramePosition> = UnsafeMutablePointer(&frame)
var n_time: Float = Float.zero
var n_time_t: UnsafeMutablePointer<Float> = UnsafeMutablePointer(&n_time)
var normalized_times_ref: UnsafeMutablePointer<Float>? = nil;


@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    
    override init() {
        let main_mixer_node: AVAudioMixerNode = audio_engine.mainMixerNode
        let audio_format: AVAudioFormat = AVAudioFormat(standardFormatWithSampleRate: audio_engine.mainMixerNode.outputFormat(forBus: 0).sampleRate, channels: audio_engine.mainMixerNode.outputFormat(forBus: 0).channelCount )!
        
        func scale(min_new: Float, max_new: Float, val_old: Float, min_old: Float, max_old: Float) -> Float {
            let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
            return val_new;
        }
        
        func generateFrequencies(root_frequency: Float, harmonic_factor: Float, frame_count: Int) -> [Float] {
            var root_frequency_samples: [Float]  = [Float](repeating: Float.zero, count: frame_count)
            var harmonic_factor_samples: [Float] = [Float](repeating: Float.zero, count: frame_count)
            let combinedSamples                  = (Int.zero ..< frame_count).map { i in
                let time: Float                  = scale(min_new: Float.zero, max_new: 1.0, val_old: Float(i), min_old: Float.zero, max_old: Float(~(-frame_count))) // Float(Float(i) / Float(frame_count))
                root_frequency_samples[i]        = 0.5 * sinf(tau * time * root_frequency) // sinf(tau * rootFrequency * time)
                harmonic_factor_samples[i]       = 0.5 * cosf(tau * time * harmonic_factor) //sinf(tau * time * harmonicFactor) // cosf(tau * (rootFrequency * harmonicFactor) * time)
                return root_frequency_samples[i] + harmonic_factor_samples[i]; //((2.f * (sinf(rootFreqSamples[i] + harmonicFreqSamples[i]) * cosf(rootFreqSamples[i] - harmonicFreqSamples[i]))) / 2.f * (1.0 - 0.5)); // (rootFreqSamples[i] + harmonicFreqSamples[i])
            }
            
            return combinedSamples
        }
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in
            let signalSamples    = generateFrequencies(root_frequency: root, harmonic_factor: harmonic, frame_count: Int(frameCount)) //mixSignals(frameCount: Int(frameCount), array1: rootFrequency, array2: harmonicFrequency)
            let ablPointer       = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftChannelData  = ablPointer[0]
            let rightChannelData = ablPointer[1]
            let leftBuffer: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(leftChannelData)
            let rightBuffer: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(rightChannelData)
            signalSamples.withUnsafeBufferPointer { sourceBuffer in
                leftBuffer.baseAddress!.initialize(from: sourceBuffer.baseAddress!, count: Int(frameCount))
                rightBuffer.baseAddress!.initialize(from: sourceBuffer.baseAddress!, count: Int(frameCount))
            }
            return noErr
        })
        
        audio_engine.attach(audio_source_node)
        audio_engine.connect(audio_source_node, to: main_mixer_node, format: audio_format)
    }
}

