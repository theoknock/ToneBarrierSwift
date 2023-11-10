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

var root: Float32     = Float32(440.0)
let harmonic: Float32 = Float32(440.0 * (5.0/4.0))
let amplitude: Float32 = Float32(0.5)
let tau: Float32      = Float32(2.0 * Float32.pi)
var frame: AVAudioFramePosition = Int64.zero
var frame_t: UnsafeMutablePointer<AVAudioFramePosition> = UnsafeMutablePointer(&frame)
var n_time: Float32 = Float32.zero
var n_time_t: UnsafeMutablePointer<Float32> = UnsafeMutablePointer(&n_time)
var normalized_times_ref: UnsafeMutablePointer<Float32>? = nil;


@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    
    
    override init() {
        let main_mixer_node: AVAudioMixerNode = audio_engine.mainMixerNode
        let audio_format: AVAudioFormat       = AVAudioFormat(standardFormatWithSampleRate: audio_engine.mainMixerNode.outputFormat(forBus: 0).sampleRate, channels: audio_engine.mainMixerNode.outputFormat(forBus: 0).channelCount )!
        let buffer_length: Int              = Int(audio_format.sampleRate) * Int(audio_format.channelCount) * Int(2)

        
        func scale(min_new: Float32, max_new: Float32, val_old: Float32, min_old: Float32, max_old: Float32) -> Float32 {
            let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
            return val_new;
        }
        
        func generateFrequencies(root_frequency: Float32, harmonic_factor: Float32, frame_count: Int) -> [Float32] {
            var root_frequency_samples: [Float32]  = [Float32](repeating: Float32.zero, count: frame_count)
            var harmonic_factor_samples: [Float32] = [Float32](repeating: Float32.zero, count: frame_count)
            let combinedSamples                  = (Int.zero ..< frame_count).map { i in
                let time: Float32                  = Float32(scale(min_new: -1.0, max_new: 1.0, val_old: Float32(i), min_old: -1.0, max_old: Float32(frame_count - 1))) //Float32(~(-frame_count))))
                root_frequency_samples[i]        = cosf(tau * time * root_frequency)
                harmonic_factor_samples[i]       = cosf(tau * time * harmonic_factor)
                return root_frequency_samples[i] + harmonic_factor_samples[i];
            }
            
            return combinedSamples
        }
        
        func makeIncrementerWithReset(maximumValue: Int) -> ((Int) -> [Int]) {
          var counter = 0
          let counter_max = maximumValue
          
          func incrementCounter(count: Int) -> [Int] {
            var numbersArray = [Int](repeating: 0, count: count)
            for index in (0..<count) {
              numbersArray[index] = counter
              counter += 1
              if counter == counter_max {
                counter = 0
              }
            }
            return numbersArray
          }

          return incrementCounter
        }

        let incrementer = makeIncrementerWithReset(maximumValue: buffer_length)
        

        var currentPhase: Float32   = Float32.zero
        var phaseIncrement: Float32 = (tau / Float32(audio_format.sampleRate)) * root
        var currentPhase_h: Float32   = Float32.zero
        let phaseIncrement_h: Float32 = (tau / Float32(audio_format.sampleRate)) * root + (Float32.pi / Float32(2.0))
        
        func generateFrequency(frame_count: Int) -> [Float32] {
            var frequency_samples: [Float32] = [Float32](repeating: Float32.zero, count: frame_count)
            var frequency_samples_h: [Float32] = [Float32](repeating: Float32.zero, count: frame_count)
            let frame_indicies: [Int] = incrementer(frame_count).map { index in
                return index
            }
            let signal_samples = (Int.zero ..< frame_count).map { i in
                // get value at i in frame_indicies and set phaseIncrement to a new value if frame_indicies[i] == 0
                if frame_indicies[i] == 0 {
                    print(i)
                    phaseIncrement = (tau / Float32(audio_format.sampleRate)) * Float32(root * (5.0/4.0))
                }
                frequency_samples[i] = sin(currentPhase) * amplitude
                frequency_samples_h[i] = sin(currentPhase_h) * amplitude
                
                defer {
                    (currentPhase = ((currentPhase + phaseIncrement)).truncatingRemainder(dividingBy: tau))
                    (currentPhase_h = ((currentPhase_h + phaseIncrement_h)).truncatingRemainder(dividingBy: tau))
                 }
                
                return frequency_samples[i] + frequency_samples_h[i];
            }
            return signal_samples
        }
        
//        let myCounter = Counter(start_index: Int.zero, end_index: Int((audio_engine.mainMixqerNode.outputFormat(forBus: 0).sampleRate)))
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in

            let signalSamples    = generateFrequency(frame_count: Int(frameCount)) //generateFrequencies(root_frequency: root, harmonic_factor: harmonic, frame_count: Int(frameCount))
            let ablPointer       = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftChannelData  = ablPointer[0]
            let rightChannelData = ablPointer[1]
            let leftBuffer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(leftChannelData)
            let rightBuffer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(rightChannelData)
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

