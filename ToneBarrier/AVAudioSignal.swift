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
import GameKit

var root:         Float32 = Float32(440.0)
var harmonic:     Float32 = Float32(root  * (3.0/2.0))
var root_:        Float32 = Float32(root  *  2.0)
var harmonic_:    Float32 = Float32(root_ * (3.0/2.0))
var amplitude:    Float32 = Float32(0.25)
var envelope:     Float32 = Float32(1.0)
let tau:          Float32 = Float32(Float32.pi * 2.0)
let phase_offset: Float32 = Float32(Float32.pi / 2.0)


func scale(min_new: Float32, max_new: Float32, val_old: Float32, min_old: Float32, max_old: Float32) -> Float32 {
    let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
    return val_new;
}


@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    
    
    override init() {
        let main_mixer_node: AVAudioMixerNode = audio_engine.mainMixerNode
        let audio_format: AVAudioFormat       = AVAudioFormat(standardFormatWithSampleRate: audio_engine.mainMixerNode.outputFormat(forBus: 0).sampleRate, channels: audio_engine.mainMixerNode.outputFormat(forBus: 0).channelCount )!
        let buffer_length: Int32 = Int32(audio_format.sampleRate) * Int32(audio_format.channelCount)
        
        
        
        
        //        var normalized_random_generator: (_ gamma: Float32) -> (() -> Float32) = { gamma in
        //            var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
        //            var random: Float32 = Float32.zero // Use a exponential or logarithmic curve to weight results
        //            return {
        //                return {
        //                    random = pow(Float32.random(in: (0.0...1.0), using: &generator), gamma)
        //
        //                    return random
        //                }
        //            }()
        //        }
        //
        //        /** --------------------------------  **/
        //
        //        func normalized_random_generator(range: Range<Float32>, gamma: Float32) {
        //
        //        }
        //
        //        func randomGenerator(using generator: (() -> Float32) -> (() -> Float32)) -> Float32 {
        //            func randomPianoNoteFrequency() -> Float32 {
        //                let note: Float32 = randomizer()
        //                let frequency = 440.0 * pow(2.0, (floor(note * 88.0) - 49.0) / 12.0)
        //
        //                return frequency
        //            }
        //
        //            var randomizer = generator(randomPianoNoteFrequency) // Use a exponential or logarithmic curve to weight results
        //
        //            return randomizer()
        //        }
        
        
        func scaled_random_generator_exp(mid: Float32, lower: Float32, upper: Float32) -> Float32 {
            var r: Float32 = Float32.random(in: (Float32.leastNonzeroMagnitude...1.0))
            var s: Float32 = scale(min_new: lower, max_new: upper, val_old: r, min_old: Float.zero, max_old: 1.0)
            var x: Float32 = pow(s, 1.0 / mid)
            print("\(r)\t--->\t\(s)\t--->\t\(x)")
            
            return x
        }
        
        func scaled_random_generator_eulers(mid: Float32, lower: Float32, upper: Float32) -> Float32 {
            var r: Float32 = Float32.random(in: (Float32.leastNonzeroMagnitude...1.0))
            var e: Float32 = Float32(expf(pow(-(r / mid), 2.0)))  //(pow(-r, 2.0)))
            print("\(r)\t--->\t\(e)")
//            var s: Float32 = scale(min_new: lower, max_new: upper, val_old: r, min_old: Float.zero, max_old: 1.0)
//            var x: Float32 = pow(s, 1.0 / mid)
//            print("\(r)\t--->\t\(s)\t--->\t\(x)")
            
            return e
        }
        
        func scaled_random_generator_sinc(mid: Float32, lower: Float32, upper: Float32) -> Float32 {
            var r: Float32 = Float32.random(in: (-1.0...1.0))
//            var x: Float32 = pow(r, 1.0 / mid)
//            var s: Float32 = scale(min_new: lower, max_new: upper, val_old: x, min_old: -1.0, max_old: 1.0)
            
            var a: Float32 = (Float32.pi * mid)
            var t: Float32 = a * r
            var d: Float32 = sin(t) / t
            var v: Float32 = scale(min_new: 0.0, max_new: 1.0, val_old: d, min_old: -1.0, max_old: 1.0)
            print("\(r)\t--->\t\(d)\t--->\t\(v)")
            
            return v
        }
        
        func pianoNoteFrequency() -> Float32 {
            let c: Float32 = scaled_random_generator_sinc(mid: 4.0, lower: Float.zero, upper: 1.0)
            let f: Float32 = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
            
            return f
        }
        
        func randomDurationFrequency(multiplier: Float32, exponent: Float32) -> Float32 {
            var subd: Float32 = Float32.random(in: (Float32.zero...1.0))
            let frequency: Float32 = scale(min_new: 0.125, max_new: 0.875, val_old: subd, min_old: Float32.zero, max_old: 1.0)
            
            return frequency
        }
        
        // To-Do: makeOscillatorWithReset
        func makeIncrementerWithReset(maximumValue: Int32) -> (Int32) -> ([Int32], [Float32]) {
            let counter_max = maximumValue
            var counter = Int32.zero
            
            func incrementCounter(count: Int32) -> ([Int32], [Float32]) {
                var int32Array   = [Int32]()
                var float32Array = [Float32]()
                
                return {
                    int32Array.append(contentsOf: (Int32.zero ..< count).map { index in
                        let value = ((counter_max ^ Int32.zero) ^ (counter ^ counter_max))
                        
                        counter = (-(~(value)))
                        if counter == counter_max {
                            counter = Int32.zero
                        }
                        
                        let time: Float32 = Float32(scale(min_new: Float32.zero, max_new: 1.0, val_old: Float32(counter), min_old: Float32.zero, max_old: Float32(maximumValue)))
                        float32Array.append(time)
                        
                        
                        return counter
                    })
                    
                    func makePersistentProperty() -> (Int32) -> Int32 {
                        var storedValue: Int32 = 0
                        
                        return { newValue in
                            storedValue = newValue
                            return storedValue
                        }
                    }
                    
                    return (int32Array, float32Array)
                }()
            }
            return incrementCounter
        }
        
        let incrementer = makeIncrementerWithReset(maximumValue: Int32(buffer_length))
        
        /** --------------------------------  **/
        
        func generateFrequencies(frame_count: Int32) -> [Float32] {
            let frame_indicies = incrementer(frame_count)
            var combined_frequency_samples: [Float32] = [Float32]() // [Float32](repeating: Float32.zero, count: frame_indicies.1.count)
            combined_frequency_samples.append(contentsOf: frame_indicies.0.enumerated().map({ kv in
                if kv.element == Int32.zero {
                    harmonic = pianoNoteFrequency()
                    root = harmonic * (2.0 / 3.0)
                }
                
                // Each tone-pair in a dyad is modulated by an amplitude with almost identical characteristics except for the attack rate:
                //      - The rate of attack for the first tone-pair is gradual; and,
                //      - for the second, sharp.
                //      - The transition between the two will be more distinct (which makes for a better ToneBarrier score).
                let amplitude_  : Float32 = Float32(0.5 * cos(0.5 * Float32.pi * frame_indicies.1[kv.offset]))
                let amplitude_b : Float32 = Float32(cos(Float32.pi * frame_indicies.1[kv.offset]))
                let root_       : Float32 = Float32(cos(tau * frame_indicies.1[kv.offset] * root))
                let root_b      : Float32 = Float32(cos(Float32.pi * frame_indicies.1[kv.offset]))
                let harmonic_   : Float32 = Float32(cos(tau * frame_indicies.1[kv.offset] * harmonic))
                let harmonic_b  : Float32 = Float32(sin(2.0 * tau * frame_indicies.1[kv.offset] * harmonic))
                
                let wave_1 : Float32 = Float32(sin(2.0 * tau * frame_indicies.1[kv.offset] * harmonic + (frame_indicies.1[kv.offset] * (0.5 * tau))))
                let wave_2 : Float32 = Float32(sin(2.0 * tau * frame_indicies.1[kv.offset] * harmonic - (frame_indicies.1[kv.offset] * (0.5 * tau))))
                
                return (wave_1 + wave_2) / 2.0
                
//                return (root_b + harmonic_b)
//                return (-amplitude_ * (root_ + harmonic_))
            }))
    
            return combined_frequency_samples
        }
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in
            let signalSamples    = generateFrequencies(frame_count: Int32(frameCount))
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

