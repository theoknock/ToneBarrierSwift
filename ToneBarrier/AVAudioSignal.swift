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

class Counter {
    // Counter variable that retains its value between calls
    private var count: Int
    private var limit: Int
    
    init(start_index: Int, end_index: Int) {
        self.count = start_index
        self.limit = end_index
    }
    
    func increment(by value: Int) {
        // Calculate how much space is left before reaching the limit
        let spaceRemaining = limit - count
        
        // Check if the increment value will exceed the limit
        if value >= spaceRemaining {
            // Calculate the remainder by finding the excess
            let remainder = value - spaceRemaining
            
            // Set the counter to the remainder
            count = remainder
        } else {
            // If the limit is not exceeded, just add the value to the count
            count += value
        }
        
        // Print the current count
        print("Current count is: \(count)")
    }
}

var root: Float     = Float(440.0)
let harmonic: Float = Float(880.0)
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
        let audio_format: AVAudioFormat       = AVAudioFormat(standardFormatWithSampleRate: audio_engine.mainMixerNode.outputFormat(forBus: 0).sampleRate, channels: audio_engine.mainMixerNode.outputFormat(forBus: 0).channelCount )!
        
        func scale(min_new: Float, max_new: Float, val_old: Float, min_old: Float, max_old: Float) -> Float {
            let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
            return val_new;
        }
        
        func generateFrequencies(root_frequency: Float, harmonic_factor: Float, frame_count: Int) -> [Float] {
            var root_frequency_samples: [Float]  = [Float](repeating: Float.zero, count: frame_count)
            var harmonic_factor_samples: [Float] = [Float](repeating: Float.zero, count: frame_count)
            let combinedSamples                  = (Int.zero ..< frame_count).map { i in
                let time: Float                  = Float(scale(min_new: -1.0, max_new: 1.0, val_old: Float(i), min_old: -1.0, max_old: Float(frame_count - 1))) //Float(~(-frame_count))))
                root_frequency_samples[i]        = cosf(tau * time * root_frequency)
                harmonic_factor_samples[i]       = cosf(tau * time * harmonic_factor)
                return root_frequency_samples[i] + harmonic_factor_samples[i];
            }
            
            return combinedSamples
        }
        
        var currentPhase: Float   = Float.zero
        let phaseIncrement: Float = (tau / Float(audio_format.sampleRate)) * root
        var currentPhase_h: Float   = Float.zero
        let phaseIncrement_h: Float = (tau / Float(audio_format.sampleRate)) * harmonic
        func generateFrequency(frame_count: Int) -> [Float] {
            var frequency_samples: [Float] = [Float](repeating: Float.zero, count: frame_count)
            var frequency_samples_h: [Float] = [Float](repeating: Float.zero, count: frame_count)
            let signal_samples = (Int.zero ..< frame_count).map { i in
                frequency_samples[i] = sine(currentPhase) * amplitude
                frequency_samples_h[i] = sine(currentPhase_h) * amplitude
                
                defer {
                    currentPhase += phaseIncrement
                    currentPhase = currentPhase.truncatingRemainder(dividingBy: tau)
                    currentPhase += (currentPhase < 0) ? tau : 0
                    currentPhase_h += phaseIncrement_h
                    currentPhase_h = currentPhase_h.truncatingRemainder(dividingBy: tau)
                    currentPhase_h += (currentPhase_h < 0) ? tau : 0
                 }
                
                return frequency_samples[i] * frequency_samples_h[i];
            }
            return signal_samples
        }
        
        let myCounter = Counter(start_index: Int.zero, end_index: Int((audio_engine.mainMixerNode.outputFormat(forBus: 0).sampleRate)))
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in
            //            myCounter.increment(by: Int(frameCount))
            let signalSamples    = generateFrequency(frame_count: Int(frameCount)) //generateFrequencies(root_frequency: root, harmonic_factor: harmonic, frame_count: Int(frameCount))
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

