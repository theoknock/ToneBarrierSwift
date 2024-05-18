//
//  TetradBuffer.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 5/12/24.
//

import Foundation
import AVFoundation
import AVFAudio
import Algorithms

class TetradBuffer {
    //    func generateFrequencies(frame_count: Int) -> [[Float32]] {
    //            let frequencies: [([(Double, Double)], [(Double, Double)])] = [
    //                ([(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency)], [(tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)]),
    //                ([(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency)], [(tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)])
    //            ]
    //        var dyadFrequencies: [[(Double, Double)]]
    //        var harmonyFrequencies: [(Double, Double)]
    //        var harmonyDurations: [(Int32, Int32)]
    //
    //        let audio_buffer: [[Float32]] = ({ (operation: (Int) -> (() -> [[Float32]])) in
    //            operation(frame_count)()
    //        })( { number in
    //            var channel_samples: (Double, Double)  = (Double.zero, Double.zero)
    //            var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: number), Array(repeating: Float32.zero, count: number)]
    //
    //            for i in 0..<number {
    //                let n: Int32 = frameIterator.next()!
    //                let t: Double = Double(n) / (Double(buffer_length) - 1.0)
    //                print("\(n)\t\(i)\t\(t)")
    //                if n == 0 {
    //                    tetrad = tetradBuffer.generateTetrad()
    //                    //            let frequencies: [([(Double, Double)], [(Double, Double)])] = [
    //                    //                ([(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency)], [(tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)]),
    //                    //                ([(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency)], [(tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)])
    //                    //            ]
    //                    dyadFrequencies = [
    //                        [(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency), (tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)],
    //                        [(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency), (tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)]
    //                    ]
    //
    //                    harmonyFrequencies = [dyadFrequencies[0][0], dyadFrequencies[1][0]]
    //
    //                    harmonyDurations = [
    //                        (Int32((tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(buffer_length))),
    //                        (Int32((tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(buffer_length)))
    //                    ]
    //                } else if n == harmonyDurations[0].0 {
    //                    harmonyFrequencies[0] = dyadFrequencies[0][1]
    //                } else if n == harmonyDurations[1].0 {
    //                    harmonyFrequencies[1] = dyadFrequencies[1][1]
    //                }
    //
    //                channel_samples = (Double(sin(tau * harmonyFrequencies[0].0 * t) + sin(tau * harmonyFrequencies[0].1 * t)),
    //                                   Double(sin(tau * harmonyFrequencies[1].0 * t) + sin(tau * harmonyFrequencies[1].1 * t)))
    //                channel_signals[0][i] = Float32(channel_samples.0)
    //                channel_signals[1][i] = Float32(channel_samples.1)
    //            }
    //            return {
    //                channel_signals
    //            }
    //        })
    //
    //        return audio_buffer
    //    }
    
    struct Tetrad {
        struct Dyad {
            struct Harmony {
                struct Tone {
                    var frequency: (Double, Double) = (Double.zero, Double.zero)
                    //                    init(frequency: (Double, Double)) {
                    //                        self.frequency = frequency
                    //                    }
                }
                var duration: Double
                var tones: [Tone]
                init(duration: Double) {
                    self.duration = duration
                    var frequencies: (Double) -> (Double, Double) = { key in
                        let frequencyLowerBound = 400.0
                        let frequencyUpperBound = 3000.0
                        let threshold = 2000.0
                        let probabilityThreshold = 1600.0 / 3600.0
                        
                        let root: Double = {
                            if Double.random(in: 0..<1) > probabilityThreshold {
                                return Double.random(in: threshold...frequencyUpperBound)
                            } else {
                                return Double.random(in: frequencyLowerBound..<threshold)
                            }
                        }()
                        let harmonic = root * key
                        
                        return (root, harmonic)
                    }
                    tones = [
                        Tone.init(frequency: frequencies((5.0 / 4.0))),
                        Tone.init(frequency: frequencies((5.0 / 4.0)))
                    ]
                }
            }
            var harmonies: [Harmony]
            var durations: (Double, Double)
            init() {
                self.durations = {
                    let a: Double = 2.0000
                    let b: Double = 0.3125
                    let c: Double = 1.6875
                    let d: Double = 0.3125
                    
                    let fullRange  = b...c
                    let q = Double.random(in: fullRange)
                    
                    var validRanges: [ClosedRange<Double>] = []
                    
                    let down = q - d
                    if (b <= down) {
                        
                        let downRange = b...down
                        validRanges.append(fullRange.clamped(to: downRange))
                    }
                    let
                    up = q + d
                    if (up <= c) {
                        let upRange = up...c
                        validRanges.append(fullRange.clamped(to: upRange))
                    }
                    
                    let range = validRanges.randomElement()!
                    let r = Double.random(in: range)
                    
                    return (q, r)
                }()
                
                harmonies = [
                    Harmony.init(duration: durations.0),
                    Harmony.init(duration: durations.1)
                ]
            }
        }
        var dyads: [Dyad]
        var bufferLength: Int = 88200
        var cycleFrames: CycledSequence<Array<Int>>
        var frameIterator: CycledSequence<Array<Int>>.Iterator
        
        var samplesIterator: (CycledSequence<Array<Float32>>.Iterator, CycledSequence<Array<Float32>>.Iterator) {
            let tau: Double =  Double(Double.pi * 2.0)
            var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(bufferLength)), Array(repeating: Float32.zero, count: bufferLength)]
            let audio_buffer: [[Float32]] =  ({ (operation: (Int) -> (() -> [[Float32]])) in
                operation(bufferLength)()
            })( { number in
                for n in 0..<number {
                    let t: Double = Double(Double(n) / (Double(bufferLength) - 1.0))
                    
                    (n >= 0 && n < 20500)
                    ? {
                        channel_signals[0][n] = Float32(sin(tau * dyads[0].harmonies[0].tones[0].frequency.0 * t) + sin(tau * dyads[0].harmonies[0].tones[0].frequency.1 * t))
                        channel_signals[1][n] = Float32(sin(tau * dyads[1].harmonies[0].tones[0].frequency.0 * t) + sin(tau * dyads[1].harmonies[0].tones[0].frequency.1 * t))
                    }()
                    : {
                        (n >= 0 && n < 41000)
                        ? {
                            channel_signals[0][n] = Float32(sin(tau * dyads[0].harmonies[1].tones[0].frequency.0 * t) + sin(tau * dyads[0].harmonies[1].tones[0].frequency.1 * t))
                            channel_signals[1][n] = Float32(sin(tau * dyads[1].harmonies[1].tones[0].frequency.0 * t) + sin(tau * dyads[1].harmonies[1].tones[0].frequency.1 * t))
                        }()
                        : {
                            (n >= 41000 && n < 61500)
                            ? {
                                channel_signals[0][n] = Float32(sin(tau * dyads[0].harmonies[0].tones[1].frequency.0 * t) + sin(tau * dyads[0].harmonies[0].tones[1].frequency.1 * t))
                                channel_signals[1][n] = Float32(sin(tau * dyads[1].harmonies[0].tones[1].frequency.0 * t) + sin(tau * dyads[1].harmonies[0].tones[1].frequency.1 * t))
                            }()
                            : {
                                channel_signals[0][n] = Float32(sin(tau * dyads[0].harmonies[1].tones[1].frequency.0 * t) + sin(tau * dyads[0].harmonies[1].tones[1].frequency.1 * t))
                                channel_signals[1][n] = Float32(sin(tau * dyads[1].harmonies[1].tones[1].frequency.0 * t) + sin(tau * dyads[1].harmonies[1].tones[1].frequency.1 * t))
                                
                            }()
                        }()
                    }()
                }
                return {
                    channel_signals
                }
            })
            
            return (audio_buffer[0].cycled().makeIterator(), audio_buffer[1].cycled().makeIterator())
        }
        
        init(bufferLength: Int) {
            dyads = [
                Dyad.init(),
                Dyad.init()
            ]
            
            cycleFrames = Array(0..<bufferLength).cycled()
            frameIterator = cycleFrames.makeIterator()
        }
        
    }
    
    //    func generateFrequencies(bufferLength: Int, frame_count: Int) -> [[Float32]] {
    //        var tetrad: Tetrad = Tetrad.init(bufferLength: bufferLength)
    //
    //        var harmonyFrequencies: [[Double]] = [
    //            [tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency],
    //            [tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency]
    //        ]
    //        var harmonyDurations: [(Int32, Int32)] = [
    //            (Int32((tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(bufferLength)), Int32((tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(bufferLength))),
    //            (Int32((tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(bufferLength)), Int32((tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(bufferLength)))
    //        ]
    //
    //        let audio_buffer: [[Float32]] = ({ (operation: (Int) -> (() -> [[Float32]])) in
    //            operation(frame_count)()
    //        })( { number in
    //            var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(number)), Array(repeating: Float32.zero, count: number)]
    //
    //            for i in 0..<number {
    //                let n: Int = tetrad.frameIterator.next()!
    //                let t: Double = Double(Double(n) / (Double(bufferLength) - 1.0))
    //                print("\(n)\t\(i)\t\(t)")
    //                if n == 0 {
    //                    tetrad = Tetrad.init(bufferLength: bufferLength)
    //                    harmonyFrequencies = [
    //                        [tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency],
    //                        [tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency]
    //                    ]
    //
    //                    harmonyDurations = [
    //                        (Int32(Double(tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(bufferLength)), Int32(Double(tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(bufferLength))),
    //                        (Int32(Double(tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(bufferLength)), Int32(Double(tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(bufferLength)))
    //                    ]
    //                } else if n == harmonyDurations[0].0 {
    //                    harmonyFrequencies[0] = [tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency]
    //                } else if n == harmonyDurations[1].0 {
    //                    harmonyFrequencies[1] = [tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency]
    //                }
    //
    //                channel_signals[0][i] = Float32(sin(tau * harmonyFrequencies[0][0] * t) + sin(tau * harmonyFrequencies[0][1] * t))
    //                channel_signals[1][i] = Float32(sin(tau * harmonyFrequencies[1][0] * t) + sin(tau * harmonyFrequencies[1][1] * t))
    //            }
    //            return {
    //                channel_signals
    //            }
    //        })
    //
    //        return audio_buffer
    //    }
    
    
    //func buffer(tetrad: Tetrad = Tetrad.init(), samples: Int, rate: Int) -> [[Float32]] {
    //            let frequencies: [([(Double, Double)], [(Double, Double)])] = [
    //                ([(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency)], [(tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)]),
    //                ([(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency)], [(tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)])
    //            ]
    //            var dyadFrequencies: [[(Double, Double)]] = [
    //                [(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency), (tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)],
    //                [(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency), (tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)]
    //            ]
    //            var harmonyFrequencies: [(Double, Double)] = [dyadFrequencies[0][0], dyadFrequencies[1][0]]
    //            var harmonyDurations:   [(Int32, Int32)]   = [
    //                (Int32((tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(samples)), Int32((tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(samples))),
    //                (Int32((tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(samples)), Int32((tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(samples)))]
    //
    //            let audio_buffer: [[Float32]] = ({ (operation: (Int) -> (() -> [[Float32]])) in
    //                operation(samples)()
    //            })( { number in
    //                var channel_samples: (Double, Double)  = (Double.zero, Double.zero)
    //                var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: number), Array(repeating: Float32.zero, count: number)]
    //
    //                for i in 0..<number {
    //                    let n: Int32 = frameIterator.next()!
    //                    let t: Double = Double(n) / (Double(buffer_length) - 1.0)
    //                    print("\(n)\t\(i)\t\(t)")
    //                    if n == 0 {
    //                        tetrad = tetradBuffer.generateTetrad()
    //                        //            let frequencies: [([(Double, Double)], [(Double, Double)])] = [
    //                        //                ([(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency)], [(tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)]),
    //                        //                ([(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency)], [(tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)])
    //                        //            ]
    //                        dyadFrequencies = [
    //                            [(tetrad.dyads[0].harmonies[0].tones[0].frequency, tetrad.dyads[0].harmonies[0].tones[1].frequency), (tetrad.dyads[0].harmonies[1].tones[0].frequency, tetrad.dyads[0].harmonies[1].tones[1].frequency)],
    //                            [(tetrad.dyads[1].harmonies[0].tones[0].frequency, tetrad.dyads[1].harmonies[0].tones[1].frequency), (tetrad.dyads[1].harmonies[1].tones[0].frequency, tetrad.dyads[1].harmonies[1].tones[1].frequency)]
    //                        ]
    //
    //                        harmonyFrequencies = [dyadFrequencies[0][0], dyadFrequencies[1][0]]
    //
    //                        harmonyDurations = [
    //                            (Int32((tetrad.dyads[0].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[0].harmonies[1].duration / 2.0) * Double(buffer_length))),
    //                            (Int32((tetrad.dyads[1].harmonies[0].duration / 2.0) * Double(buffer_length)), Int32((tetrad.dyads[1].harmonies[1].duration / 2.0) * Double(buffer_length)))
    //                        ]
    //                    } else if n == harmonyDurations[0].0 {
    //                        harmonyFrequencies[0] = dyadFrequencies[0][1]
    //                    } else if n == harmonyDurations[1].0 {
    //                        harmonyFrequencies[1] = dyadFrequencies[1][1]
    //                    }
    //
    //                    channel_samples = (Double(sin(tau * harmonyFrequencies[0].0 * t) + sin(tau * harmonyFrequencies[0].1 * t)),
    //                                       Double(sin(tau * harmonyFrequencies[1].0 * t) + sin(tau * harmonyFrequencies[1].1 * t)))
    //                    channel_signals[0][i] = Float32(channel_samples.0)
    //                    channel_signals[1][i] = Float32(channel_samples.1)
    //                }
    //                return {
    //                    channel_signals
    //                }
    //            })
    //
    //            return audio_buffer
    //        }
}
