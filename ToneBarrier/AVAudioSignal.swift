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
import Algorithms

var octave:       Float32 = Float32(440.0 * 2.0)
/**
 The lowest frequency (or note) of a tone pair and/or tone-pair dyad. This fundamental frequency is the basis for 'harmonic' and 'octave', and the combination tones.
 */
var root:         Float32 = Float32(octave * 0.5)
var harmonic:     Float32 = Float32(root * (3.0/2.0))

var root_:        Float32 = Float32(root  *  2.0)
var harmonic_:    Float32 = Float32(root_ * (3.0/2.0))
var amplitude:    Float32 = Float32(0.25)
var envelope:     Float32 = Float32(1.0)
let tau:          Double  = Double(Double.pi * 2.0)
let theta:        Float32 = Float32(Float32.pi / 2.0)
let trill:        Float32 = Float32.zero
let tremolo:      Float32 = Float32(1.0)
var split:        Int32   = Int32(2)
var duration:     Int32   = Int32.zero

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    let audio_engine: AVAudioEngine = AVAudioEngine()
    
    override init() {
        let main_mixer_node: AVAudioMixerNode = audio_engine.mainMixerNode
        let audio_format: AVAudioFormat       = AVAudioFormat(standardFormatWithSampleRate: audio_engine.mainMixerNode.outputFormat(forBus: Int.zero).sampleRate, channels: audio_engine.mainMixerNode.outputFormat(forBus: Int.zero).channelCount )!
        let buffer_length: Int32              = Int32(audio_format.sampleRate) * Int32(audio_format.channelCount)
        
        func pianoNoteFrequency() -> Float32 {
            let c: Float32 = Float32.random(in: (0.5...1.0))
            let f: Float32 = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
            
            return f
        }
        
        var duration = buffer_length
        var cycleFrames = Array(0..<buffer_length).cycled()
        var frameIterator =  cycleFrames.makeIterator()
        var cycleTime    = Array(0..<buffer_length).cycled()
        var timeIterator =  cycleTime.makeIterator()
        
        //        var frame_indicies  = Array(0..<buffer_length)
        var n: Int32 = Int32.zero
        
    
        let e_sustain: (Float32, Float32) -> Float32 = { t,d in
            return pow(sin(Float32.pi * t), d) // 2.0 to 10.0
        }
        let e_attack: (Float32, Float32) -> Float32 = { t, d in
            return pow(sin(pow(Float32.pi * t, 0.5)), d) // 2.0 to 10.0
        }
        let e_release: (Float32, Float32) -> Float32 = { t, d in
            return pow(cos(pow(Float32.pi * t, 0.5)), d) // 2.0 to 10.0
        }
        //        let e_release: (Float32, Float32) -> Float32 = { t, d in
        //            return pow(sin(pow(Float32.pi * t, 2.0)), d) // 2.0 to 10.0
        //        }
        
        let envelopes = [e_attack, e_sustain]
        
        
        func store_note_frequency() -> (Float32) -> ([Float32]) {
            var storedOctave:   Float32 = Float32.zero
            var storedRoot:     Float32 = Float32.zero
            var storedHarmonic: Float32 = Float32.zero
            var storedSum: Float32 = Float32.zero
            
            return { newValue in
                storedRoot     = newValue * 0.5
                storedOctave   = newValue
                storedHarmonic = newValue * (2.0 / 3.0)
                return [storedRoot, storedHarmonic, storedOctave]
            }
        }
        let note_frequencies  = store_note_frequency()
        var combination_notes = note_frequencies(pianoNoteFrequency())
        
        /// Generates an array of signal samples for the specified number of frames.
        ///
        /// - Parameter frame_count: The required number of signal samples and array elements to generate.
        /// - Returns: An array of signal samples required by the ``frame_count`` parameter.
        //        func generateFrequencies(frame_count: Int) -> [[Float32]] {
        //            let tetrad: TetradBuffer.Tetrad = tetradBuffer.generateTetrad()
        //            let frequencies: [([(Double, Double)], [(Double, Double)])] = [
        //                ([(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency)], [(tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)]),
        //                ([(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)], [(tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)])
        //            ]
        //            var dyadFrequencies: [(Double, Double)] = [(Double.zero, Double.zero), (Double.zero, Double.zero)]
        //            let harmonyDurations: [(Int32, Int32)] = [
        //                (Int32((tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(buffer_length))),
        //                (Int32((tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(buffer_length)))
        //            ]
        //
        //            var combined_frequency_samples: [([(Double, Double)], [(Double, Double)])] = { return (0..<frame_count).map {_ in
        //                let t: Double = Double(frameIterator.next()!) / (Double(buffer_length) - 1.0)
        //                let n: Int32 = timeIterator.next()!
        //                switch n {
        //                case 0:
        //                    dyadFrequencies[0] = frequencies[0].0[0]
        //                    dyadFrequencies[1] = frequencies[1].0[0]
        //                case harmonyDurations[0].0:
        //                    dyadFrequencies[0] = frequencies[0].0[1]
        //                case harmonyDurations[1].0:
        //                    dyadFrequencies[1] = frequencies[1].0[1]
        //                default:
        //                    dyadFrequencies[0] = (240.0, 440.0)
        //                    dyadFrequencies[1] = (640.0, 880.0)
        //                }
        ////                return
        ////                    ([(Double(tetrad.dyads[0].harmonies[0].tones[0].frequency), Double(tetrad.dyads[0].harmonies[0].tones[1].frequency)),  (Double(tetrad.dyads[0].harmonies[1].tones[0].frequency), Double(tetrad.dyads[0].harmonies[1].tones[1].frequency))],
        ////                     ([(Double(tetrad.dyads[0].harmonies[0].tones[0].frequency), Double(tetrad.dyads[0].harmonies[0].tones[1].frequency)), (Double(tetrad.dyads[0].harmonies[1].tones[0].frequency), Double(tetrad.dyads[0].harmonies[1].tones[1].frequency))]))
        //
        //                return
        //                    ([(Double(tetrad.dyads[0].harmonies[0].tones[0].frequency), Double(tetrad.dyads[0].harmonies[0].tones[1].frequency)),  (Double(tetrad.dyads[0].harmonies[1].tones[0].frequency), Double(tetrad.dyads[0].harmonies[1].tones[1].frequency))],
        //                     ([(Double(tetrad.dyads[0].harmonies[0].tones[0].frequency), Double(tetrad.dyads[0].harmonies[0].tones[1].frequency)), (Double(tetrad.dyads[0].harmonies[1].tones[0].frequency), Double(tetrad.dyads[0].harmonies[1].tones[1].frequency))]))
        //            }
        //
        //                //            var right_channel_samples: [Float32] { return (0..<frame_count).map { Float32($0) } }
        //                //            var combined_frequency_samples: [[Float32]] { zip(left_channel_samples, right_channel_samples).map { [$0, $1] } }
        //                //
        //                //            for i in 0..<frame_count {
        //                //                n = frameIterator.next()!
        //                //                switch n {
        //                //                case 0:
        //                //                    dyadFrequencies[0] = frequencies[0][0]
        //                //                    dyadFrequencies[1] = frequencies[1][0]
        //                //                case harmonyDurations[0].0:
        //                //                    dyadFrequencies[0] = frequencies[0][1]
        //                //                case harmonyDurations[1].0:
        //                //                    dyadFrequencies[1] = frequencies[1][1]
        //                //                default:
        //                //                    dyadFrequencies[0] = (240.0, 440.0)
        //                //                    dyadFrequencies[1] = (640.0, 880.0)
        //                //                }
        //                //
        //                //                let t: Double  = Double(n) / (Double(buffer_length) - 1.0)
        //                //                let left: Double  = sin(sin(tau * dyadFrequencies[0].0 * t) + sin(tau * dyadFrequencies[0].1 * t))
        //                //                let right: Double = sin(sin(tau * dyadFrequencies[1].0 * t) + sin(tau * dyadFrequencies[1].1 * t))
        //                //                left_channel_samples[i]          = Float32(left)
        //                //                right_channel_samples[i]         = Float32(right)
        //                //                combined_frequency_samples[0][i] = left_channel_samples[i]
        //                //                combined_frequency_samples[1][i] = right_channel_samples[i]
        //                //            }
        //
        //
        //            }()
        //            return combined_frequency_samples
        //        }
        
//        let serialQueue = DispatchQueue(label: "com.example.serialQueue")
//        func newGenerateFrequencies(frameCount: Int, completion: @escaping ([[Float32]]) -> Void) {
//            serialQueue.async {
//                DispatchQueue.main.async {
//                    completion(generateFrequencies(frame_count: frameCount))
//                }
//            }
//        }
        
//        func generateFrequencies(frame_count: Int) -> [[Float32]] {
//
//
//            var harmonyFrequencies: [[Double]] = [
//                [tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency],
//                [tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency]
//            ]
////            var harmonyDurations: [(Int32, Int32)] = [
////                (Int32((tetrad.dyads[0].durations.0 / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[1].durations.0 / 2.0) * Double(buffer_length))),
////                (Int32((tetrad.dyads[0].durations.1 / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[1].durations.1 / 2.0) * Double(buffer_length)))
////            ]
//
//            var harmonyDurations: [(Int32, Int32)] = [
//                (Int32(0.5 * Double(buffer_length)), Int32(0.25 * Double(buffer_length)))
//            ]
//
//            let audio_buffer: [[Float32]] =  ({ (operation: (Int) -> (() -> [[Float32]])) in
//                operation(frame_count)()
//            })( { number in
//                var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(number)), Array(repeating: Float32.zero, count: number)]
//
//                for i in 0..<number {
//                    n = frameIterator.next()!
//                    let t: Double = Double(Double(n) / (Double(buffer_length) - 1.0))
//                    if n == 0 {
//                        print("frame\t\(i)\tindex\t\(n)\t\ttime\t\(t)\t\(frame_count)")
//                    } else if n == harmonyDurations[0].0 {
//                        print("frame\t\(i)\tindex\t\(n)\ttime\t\(t)\t\(frame_count)")
////                        harmonyFrequencies[0] = [tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency]
//                        harmonyFrequencies[0] = [440.0, 640.0]
//                    } else if n == harmonyDurations[0].1 {
//                        print("frame\t\(i)\tindex\t\(n)\ttime\t\(t)\t\(frame_count)")
////                        harmonyFrequencies[1] = [tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency]
//                        harmonyFrequencies[1] = [220.0, 420.0]
//                    } else if n == (buffer_length - 1) {
//                        print("frame\t\(i)\tindex\t\(n)\ttime\t\(t)\t\(frame_count)\nEND")
////
////                        tetrad = TetradBuffer.Tetrad.init(bufferLength: Int(buffer_length))
////                        harmonyFrequencies = [
////                            [tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency],
////                            [tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency]
////                        ]
//
//                        harmonyFrequencies = [
//                            [330.0, 530.0],
//                            [710.0, 910.0]
//                        ]
//
////                        harmonyDurations = [
////                            (Int32(Double(tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32(Double(tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(buffer_length))),
////                            (Int32(Double(tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32(Double(tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(buffer_length)))
////                        ]
//
//                        harmonyDurations = [
//                            (Int32(0.5 * Double(buffer_length)), Int32(0.25 * Double(buffer_length)))
//                        ]
//                    }
//
//                    channel_signals[0][i] = Float32(sin(tau * harmonyFrequencies[0][0] * t) + sin(tau * harmonyFrequencies[0][1] * t))
//                    channel_signals[1][i] = Float32(sin(tau * harmonyFrequencies[1][0] * t) + sin(tau * harmonyFrequencies[1][1] * t))
//                }
//                return {
//                    channel_signals
//                }
//            })
//
//            return audio_buffer
//        }
        
        //            var combined_frequency_samples: [[Float32]] = (0..<frame_count).map { i in
        //                let n: Int32 = frameIterator.next()!
        //                let t: Double = Double(n) / (Double(buffer_length) - 1.0)
        //                switch n {
        //                case 0:
        //                    harmonyFrequencies[0] = dyadFrequencies[0][0]
        //                    harmonyFrequencies[1] = dyadFrequencies[1][0]
        //                case harmonyDurations[0].0:
        //                    harmonyFrequencies[0] = dyadFrequencies[0][1]
        //                case harmonyDurations[1].0:
        //                    harmonyFrequencies[1] = dyadFrequencies[1][1]
        //                default:
        //                    break
        //                }
        //
        //                // Convert each frequency pair to its respective sinusoidal waveforms and wrap them in Float32
        //                let channel_sample: [Double]  = [Double(sin(tau * harmonyFrequencies[0].0 * t) + sin(tau * harmonyFrequencies[0].1 * t)),
        //                                                 Double(sin(tau * harmonyFrequencies[1].0 * t) + sin(tau * harmonyFrequencies[1].1 * t))]
        ////                channel_signal[0][i] = channel_sample[0]
        ////                channel_signal[1][i] = channel_sample[1]
        //
        //                // two blocks that call each other alternatively until frame_count is reached until block that takes a block that creates a channel_sample every time called and returns [Float32(channel_sample[0]), Float32(channel_sample[1])]
        //
        //                return [Float32(channel_sample[0]), Float32(channel_sample[1])] // replace with closures or maps or what the hell ever
        //            }
        ////                return [channel_signal[0], channel_signal[1]]
        ////            }
        //
        //                // CHANGE THIS LINE ONLY
        //                return combined_frequency_samples
        //            }
        //
        
        func sineWaveValue(time t: Float32, duration: Float32, baseFrequency f1: Float32, trillFrequency f2: Float32, initialTrillRate: Float32, trillDecay: Float32, initialTremoloRate: Float32, tremoloDepth: Float32, tremoloDecay: Float32) -> Float32 {
            // Calculate the decreasing trill rate over time
            let trillRate = initialTrillRate * exp(-trillDecay * t)
            let trillPeriod = 1 / trillRate
            let trillTime = fmod(t, trillPeriod) / trillPeriod
            let f = f1 + (f2 - f1) * sin(trillTime * 2 * .pi)
            
            // Calculate the decreasing tremolo rate over time
            let tremoloRate = initialTremoloRate * exp(-tremoloDecay * t)
            let tremolo = 1.0 - tremoloDepth + tremoloDepth * sin(2 * .pi * t * tremoloRate)
            
            // Calculate the amplitude envelope with a linear fade-out
            let amplitudeDecayRate = 1.0 / duration
            let A = max(0.0, (1.0 - amplitudeDecayRate * t) * tremolo) // Ensures amplitude doesn't go below 0
            
            // Calculate the sine wave value with the current frequency and amplitude
            let value = A * sin(2 * Float32.pi * t * f)
            return value
        }
   
        var tetradBuffer = TetradBuffer(bufferLength: Int(buffer_length))
        var s = tetradBuffer.generateSignalSamplesIterator()

//        // Example usage
//        let processor = AudioSignalProcessor(sampleRate: 44100.0, length: 88200)
//        let frequency = 440.0
//        let signal = processor.generateSignal(frequency: frequency)
//
//        // Mixing two signals
//        let signal1 = processor.generateSignal(frequency: 440.0)
//        let signal2 = processor.generateSignal(frequency: 220.0)
//        let mixedSignal = processor.mixSignals(signal1: signal1, signal2: signal2)
//
//        // Low-pass filter example (replace with actual filter coefficients)
//        let filterCoefficients: [Double] = [0.1, 0.15, 0.5, 0.15, 0.1]
//        let filteredSignal = processor.lowPassFilter(signal: mixedSignal, filterCoefficients: filterCoefficients)
        

        func numbers(count: Int) -> [[Float32]] {
            let allNumbers: [[Float32]] = ({ (operation: (Int) -> (() -> [[Float32]])) in
                operation(count)()
            })( { number in
                var channels: [[Float32]] = [Array(repeating: Float32.zero, count: count), Array(repeating: Float32.zero, count: count)]
                //print(#function)
                for i in 0..<number {
                    if let leftSample = s.0.next(), let rightSample = s.1.next() {
                        channels[0][i] = leftSample
                        channels[1][i] = rightSample
                    } else {
//                        tetradBuffer.resetIterator()
                        s = tetradBuffer.generateSignalSamplesIterator()
                        channels[0][i] = Float32(s.0.next()!)
                        channels[1][i] = Float32(s.1.next()!)
                    }
                }
                

//                        let n = vDSP_Length(88200)
//                        let stride = vDSP_Stride(1)
//
//                        var a: Float = 0.0
//                        var b: Float = 1.0
//
//                        var timeArray = [Float](repeating: 0, count: Int(n))
//
//                        vDSP_vgen(&a, &b, &timeArray, stride, n)
//
//                        let frequency: Float = 440.0
//                        let twoPi: Float = 2.0 * .pi
//
//                        var sineWave = [Float](repeating: 0, count: Int(n))
//
//                        // Calculate sin(2pi * time * frequency)
//                        vDSP_vsmul(timeArray, stride, [twoPi * frequency], &sineWave, stride, n)
//                        vvsinf(&sineWave, sineWave, [Int32(n)])
//
//                        print(sineWave)
        
                
                return {
                    channels
                }
            })
            return allNumbers
        }
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in
            //print(#function)
            let signalSamples    = numbers(count: Int(frameCount))
            let ablPointer       = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftChannelData  = ablPointer[0]
            let rightChannelData = ablPointer[1]
            let leftBuffer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(leftChannelData)
            let rightBuffer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(rightChannelData)
            signalSamples.withUnsafeBufferPointer { sourceBuffer in
                ([Float32]([Float32](sourceBuffer[0]))).withUnsafeBufferPointer { leftSourceBuffer in
                    leftBuffer.baseAddress!.initialize(from: leftSourceBuffer.baseAddress!, count: Int(frameCount))
                }
                ([Float32]([Float32](sourceBuffer[1]))).withUnsafeBufferPointer { rightSourceBuffer in
                    rightBuffer.baseAddress!.initialize(from: rightSourceBuffer.baseAddress!, count: Int(frameCount))
                }
            }
            
            return noErr
        })
        
        var reverb: AVAudioUnitReverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(AVAudioUnitReverbPreset.largeChamber)
        reverb.wetDryMix = 50.0
        
        audio_engine.attach(audio_source_node)
        audio_engine.attach(reverb)
        
        audio_engine.connect(audio_source_node, to: reverb, format: audio_format)
        audio_engine.connect(reverb, to: main_mixer_node, format: audio_format)
    }
}
