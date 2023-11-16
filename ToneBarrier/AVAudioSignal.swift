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
            var r: Float32 = Float32.random(in: (Float32.zero...1.0))
            var s: Float32 = scale(min_new: lower, max_new: upper, val_old: r, min_old: Float.zero, max_old: 1.0)
            
            var x: Float32 = pow(s, mid)
            
            return s
        }
        
        func scaled_random_generator_sinc(mid: Float32, lower: Float32, upper: Float32) -> Float32 {
            var r: Float32 = Float32.random(in: (Float32.zero...1.0))
            var s: Float32 = scale(min_new: Float.zero, max_new: 1.0, val_old: r, min_old: lower, max_old: upper)
            
            var t: Float32 = Float32.pi * (s - mid)
            var d: Float32 = Float32(t / mid)
            var c: Float32 = Float32(sin(d) / d)
            
            return c
        }
        
        func pianoNoteFrequency() -> Float32 {
            let c: Float32 = scaled_random_generator_exp(mid: 0.666, lower: 0.333, upper: 0.888)
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
                if kv.element == Int.zero {
                    root = pianoNoteFrequency()
                    harmonic = root * (3.0 / 2.0)
                    amplitude = 3.0
                }
//                let envelope_: Float32 = scale(min_new: Float32.zero, max_new: amplitude, val_old: cos((tau * frame_indicies.1[kv.offset] * 2.0)), min_old: Float32.zero, max_old: cos(tau * pow(amplitude, 0.333)))
                let amplitude_ : Float32 = scale(min_new: Float32.zero, max_new: amplitude, val_old: Float32(0.5 * cos(Float32.pi * frame_indicies.1[kv.offset])), min_old: Float32.zero, max_old: cos(tau * pow(amplitude, 0.333)))
                let root_      : Float32 = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[kv.offset] * root), min_old: Float32.zero, max_old: cos(tau * root))
                let harmonic_  : Float32 = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[kv.offset] * harmonic), min_old: Float32.zero, max_old: cos(tau * harmonic))

                return (-amplitude_ * (root_ + harmonic_))
            }))
//            (frame_indicies.0).enumerated() { (i, element) in
//                if frame_indicies.0[Int(i)] == Int.zero {
//                    root = pianoNoteFrequency()
//                    harmonic = root * (3.0 / 2.0)
//                    amplitude = 3.0
//                }
//                
//                let amplitude_ : Float32 = scale(min_new: Float32.zero, max_new: amplitude, val_old: cos((tau * frame_indicies.1[Int(i)] * amplitude) - phase_offset), min_old: Float32.zero, max_old: cos(tau * pow(amplitude, 0.333)))
//                let root_      : Float32 = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * root), min_old: Float32.zero, max_old: cos(tau * root))
//                let harmonic_  : Float32 = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * harmonic), min_old: Float32.zero, max_old: cos(tau * harmonic))
//
//                return (amplitude_ * (root_ + harmonic_))
//            }
//            combined_frequency_samples.with  d(contentsOf: (Int32.zero ..< frame_indicies.0.count).map { i in
//                if frame_indicies.0[Int(i)] == Int.zero {
//                    root = pianoNoteFrequency()
//                    harmonic = root * (3.0 / 2.0)
//                    amplitude = 3.0
//                }
//                
//                let amplitude_ : Float32 = scale(min_new: Float32.zero, max_new: amplitude, val_old: cos((tau * frame_indicies.1[Int(i)] * amplitude) - phase_offset), min_old: Float32.zero, max_old: cos(tau * pow(amplitude, 0.333)))
//                let root_      : Float32 = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * root), min_old: Float32.zero, max_old: cos(tau * root))
//                let harmonic_  : Float32 = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * harmonic), min_old: Float32.zero, max_old: cos(tau * harmonic))
//
//                return (amplitude_ (root_ + harmonic_))
//                
////                amplitude_frequency_samples[Int(i)]  = scale(min_new: Float32.zero, max_new: amplitude, val_old: cos((tau * frame_indicies.1[Int(i)] * amplitude) - phase_offset), min_old: Float32.zero, max_old: cos(tau * pow(amplitude, 0.333)))
////                root_frequency_samples[Int(i)]       = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * root), min_old: Float32.zero, max_old: cos(tau * root))
////                harmonic_frequency_samples[Int(i)]   = scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * harmonic), min_old: Float32.zero, max_old: cos(tau * harmonic))
////                
////                return (amplitude_frequency_samples[Int(i)] * (Float32(root_frequency_samples[Int(i)] + harmonic_frequency_samples[Int(i)])))
//            })
                
            return combined_frequency_samples
        }
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in
            let signalSamples    = generateFrequencies(frame_count: Int32(frameCount)) //generateFrequencies(root_frequency: root, harmonic_factor: harmonic, frame_count: Int(frameCount))
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

