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
var harmonic:     Float32 = Float32(440.0 * (3.0/2.0))
let amplitude:    Float32 = Float32(0.25)
let tau:          Float32 = Float32(2.0 * Float32.pi)
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
        let buffer_length: Int = Int(audio_format.sampleRate) * Int(audio_format.channelCount)
        
        
        /** --------------------------------  **/
        
        enum CombinationTone {
            enum CombinationToneArpeggio: UInt {
                case CombinationToneNone
                case CombinationToneArpeggioRootOrDrone
                case CombinationToneArpeggioFifth
                case CombinationToneArpeggioOctave
                case CombinationToneArpeggioRandom
            }
            
            enum CombinationToneSum: UInt {
                case CombinationToneSumNone
                case CombinationToneRoot
                case CombinationToneArpeggioFifth
                case CombinationToneArpeggioOctave
                case CombinationToneSumRandom
            }
            
            enum CombinationToneUnitFrequency: UInt {
                case CombinationToneNone
                case CombinationTonePianoNote
                case CombinationToneHertz
            }
            
            enum MusicalNote: UInt {
                case MusicalNoteA
                case MusicalNoteBFlat
                case MusicalNoteB
                case MusicalNoteC
                case MusicalNoteCSharp
                case MusicalNoteD
                case MusicalNoteDSharp
                case MusicalNoteE
                case MusicalNoteF
                case MusicalNoteFSharp
                case MusicalNoteG
                case MusicalNoteAFlat
            };
        }
        
        
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
        
        func randomPianoNoteFrequency(multiplier: Float32, exponent: Float32) -> Float32 {
            var note: Float32 = Float32.random(in: (Float32.zero...1.0))
            var m: Float32 = exponent
            var t: Float32 = Float32.pi * (note - m)
            var d: Float32 = Float32(t / m)
            var c: Float32 = Float32(sin(d) / d)
            print(c)
            let frequency: Float32 = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
            
            return frequency
        }
        
        // To-Do: makeOscillatorWithReset
        func makeIncrementerWithReset(maximumValue: Int32) -> (Int32) -> ([Int32], [Float32]) {
            var counter = Int32.zero
            let counter_max = maximumValue
            
            func incrementCounter(count: Int32) -> ([Int32], [Float32]) {
                var int32Array   = [Int32]()
                var float32Array = [Float32]()
                
                return {
                    int32Array.append(contentsOf: (Int32.zero ..< count).map { index in
                        let value = ((counter_max ^ 0) ^ (counter ^ counter_max))
                        
                        counter = (-(~(value)))
                        if counter == counter_max {
                            counter = 0
                        }
                        
                        return counter
                    })
                    
                    float32Array.append(contentsOf: (Int32.zero ..< count).map { index in
                        let time: Float32 = Float32(scale(min_new: 0.0, max_new: 1.0, val_old: Float32(int32Array[Int(index)]), min_old: 0.0, max_old: Float32(maximumValue))) //Float32(~(-frame_count)))))
                        
                        return time
                    })
                    return (int32Array, float32Array)
                }()
            }
            return incrementCounter
        }
        
        let incrementer = makeIncrementerWithReset(maximumValue: Int32(buffer_length))
        
        /** --------------------------------  **/
        
        func generateFrequencies(frame_count: Int32) -> [Float32] {
            let frame_indicies                         = incrementer(frame_count)
            var root_frequency_samples:      [Float32] = [Float32](repeating: Float32.zero, count: Int(frame_count))
            var harmonic_frequency_samples:  [Float32] = [Float32](repeating: Float32.zero, count: Int(frame_count))
            var amplitude_frequency_samples: [Float32] = [Float32](repeating: Float32.zero, count: Int(frame_count))
            var combined_frequency_samples = [Float32]()
            combined_frequency_samples.append(contentsOf: (Int32.zero ..< frame_count).map { i in
                if frame_indicies.0[Int(i)] == Int.zero {
                    root = randomPianoNoteFrequency(multiplier: 1.0, exponent: 0.875)
                    harmonic = root * (3.0 / 2.0)
                }
                
                amplitude_frequency_samples[Int(i)]  = scale(min_new: Float32.zero, max_new: amplitude, val_old: cos(tau * frame_indicies.1[Int(i)] * amplitude), min_old: Float32.zero, max_old: cos(tau * amplitude * amplitude))
                root_frequency_samples[Int(i)]       = amplitude_frequency_samples[Int(i)] * scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * root), min_old: Float32.zero, max_old: cos(tau * root))
                harmonic_frequency_samples[Int(i)]   = amplitude_frequency_samples[Int(i)] * scale(min_new: Float32.zero, max_new: 1.0, val_old: cos(tau * frame_indicies.1[Int(i)] * harmonic), min_old: Float32.zero, max_old: cos(tau * harmonic))
                
                return Float32(root_frequency_samples[Int(i)] + harmonic_frequency_samples[Int(i)])
            })
            return combined_frequency_samples
        }
        //            combined_frequency_samples.append(contentsOf: ((Int.zero ..< Int(frame_count)).map { i in
        ////                if frame_indicies.0[i] == 0 {
        ////                    root = randomPianoNoteFrequency(multiplier: 1.0, exponent: 1.0)
        ////                    harmonic = root * (3.0 / 2.0)
        ////                }
        ////
        ////                root_frequency_samples[i]       = cos(tau * frame_indicies.1[i] * root)
        ////                harmonic_frequency_samples[i]   = cos(tau * frame_indicies.1[i] * harmonic) // (root * (harmonic * tremolo_indicies.1[i])) + phase_offset)
        ////                amplitude_frequency_samples[i]  = cos(tau * frame_indicies.1[i] * amplitude)
        ////                let scaledSamples               = Float32(scale(min_new: 0.0, max_new: 1.0, val_old: Float32((amplitude_frequency_samples * (root_frequency_samples[i] + harmonic_frequency_samples[i]))), min_old: 0.0, max_old: 2.0)) //Float32(~(-frame_count))))
        ////
        ////                return scaledSamples
        ////            }
        //
        //            return Float32.zero //combinedSamples
        //        })
        
        /** --------------------------------  **/
        
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

