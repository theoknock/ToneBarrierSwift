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


func scale(min_new: Double, max_new: Double, val_old: Double, min_old: Double, max_old: Double) -> Double {
    let val_new = min_new + (((val_old - min_old) * (max_new - (min_new))) / (max_old - min_old))
    return val_new;
}

class TetradBuffer {
    
    var tetrad: Tetrad
    var bufferLength: Int
    
    init(bufferLength: Int) {
        self.bufferLength = bufferLength
        self.tetrad = Tetrad(bufferLength: bufferLength)
    }
    
    public func generateSignalSamplesIterator() -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
        return tetrad.samplesIterator
    }
    
    public func resetIterator() {
        self.tetrad = Tetrad(bufferLength: bufferLength)
    }
    
    func pianoNoteFrequency() -> Float32 {
        let c: Float32 = Float32.random(in: (0.5...1.0))
        let f: Float32 = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
        
        return f
    }
    
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
    
    
    
    /*
     
     let note_frequencies  = store_note_frequency()
     var combination_notes = note_frequencies(pianoNoteFrequency())
     
     */
    
    
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
                    var key: Double
                    var frequency: [Double] {
                        let frequencyLowerBound = 400.0
                        let frequencyUpperBound = 3000.0
                        let threshold = 2000.0
                        let probabilityThreshold = 1600.0 / 3600.0
                        
                        var root: Double = {
                            if Double.random(in: 0.0..<1.0) > probabilityThreshold {
                                return Double.random(in: threshold...frequencyUpperBound)
                            } else {
                                return Double.random(in: frequencyLowerBound..<threshold)
                            }
                        }()
                        var harmonic = root * key
                        //                        print("\(root)\t\t\(harmonic)")
                        return [root, harmonic]
                    }
                    
                    init(key: Double) {
                        self.key = key
                    }
                }
                var duration: Double
                var tones: [Tone]
                //                var frequencies: (Double) -> (Double, Double) = { key in
                //                    let frequencyLowerBound = 400.0
                //                    let frequencyUpperBound = 3000.0
                //                    let threshold = 2000.0
                //                    let probabilityThreshold = 1600.0 / 3600.0
                //
                //                    var root: Double {
                //                        if Double.random(in: 0.0..<1.0) > probabilityThreshold {
                //                            return Double.random(in: threshold...frequencyUpperBound)
                //                        } else {
                //                            return Double.random(in: frequencyLowerBound..<threshold)
                //                        }
                //                    }
                //                    var harmonic = (Double.random(in: 0.0..<1.0) * frequencyUpperBound) * key
                //
                //                    return (root, harmonic)
                //                }
                init(duration: Double) {
                    self.duration = duration
                    //                    let frequencies: (Double) -> (Double, Double) = { key in
                    //                        let frequencyLowerBound = 400.0
                    //                        let frequencyUpperBound = 3000.0
                    //                        let threshold = 2000.0
                    //                        let probabilityThreshold = 1600.0 / 3600.0
                    //
                    //                        let root: Double = {
                    //                            if Double.random(in: 0.0...1.0) > probabilityThreshold {
                    //                                return Double.random(in: threshold...frequencyUpperBound)
                    //                            } else {
                    //                                return Double.random(in: frequencyLowerBound..<threshold)
                    //                            }
                    //                        }()
                    //                        let harmonic = root * key
                    //
                    //                        return (root, harmonic)
                    //                    }
                    tones = [
                        Tone.init(key: (5.0 / 4.0)),
                        Tone.init(key: (5.0 / 4.0))
                    ]
                }
            }
            var harmonies: [Harmony]
            var durations: [Double]
            init() {
                self.durations = {
                    let a: Double = 2.0000
                    let b: Double = scale(min_new: 0.0, max_new: 1.0, val_old: 0.3125, min_old: 0.0, max_old: 2.0)
                    let c: Double = scale(min_new: 0.0, max_new: 1.0, val_old: 1.6875, min_old: 0.0, max_old: 2.0)
                    let d: Double = scale(min_new: 0.0, max_new: 1.0, val_old: 0.3125, min_old: 0.0, max_old: 2.0)
                    
                    let fullRange  = b...c
                    let q = Double.random(in: fullRange)
                    
                    var validRanges: [ClosedRange<Double>] = []
                    
                    let down = q - d
                    if (b <= down) {
                        let downRange = b...down
                        validRanges.append(fullRange.clamped(to: downRange))
                    }
                    let up = q + d
                    if (up <= c) {
                        let upRange = up...c
                        validRanges.append(fullRange.clamped(to: upRange))
                    }
                    
                    let range = validRanges.randomElement()!
                    let r = Double.random(in: range)
                    
                    return [(q < r) ? q : r, (q < r) ? r : q]
                }()
                
                harmonies = [
                    Harmony.init(duration: durations[0]),
                    Harmony.init(duration: durations[1])
                ]
            }
        }
        var dyads: [Dyad]
        var bufferLength: Int = 88200
        var cycleFrames: CycledSequence<Array<Int>>
        var frameIterator: CycledSequence<Array<Int>>.Iterator
        
        var samplesIterator: (Array<Float32>.Iterator, Array<Float32>.Iterator) {
            let tau: Double =  Double(Double.pi * 2.0)
            var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(bufferLength)), Array(repeating: Float32.zero, count: bufferLength)]
            let audio_buffer: [[Float32]] =  ({ (operation: (Int) -> (() -> [[Float32]])) in
                operation(bufferLength)()
            })( { frames in
                
                let durationSplits: [Int] = [
                    Int(Double(frames) * dyads[0].durations[0]),
                    Int(Double(frames) * dyads[0].durations[1]),
                    Int(Double(frames) * dyads[1].durations[0]),
                    Int(Double(frames) * dyads[1].durations[1])
                ]
                print(durationSplits)
                
//                let durationSplits: [Int] = [
//                    0,
//                    Int(dyads[0].durations.0) * frames,
//                    Int(Double(frames) * 0.50),
//                    Int(Double(frames) * 0.75)
//                ]
//                
                
                let frequencies: [Double] = [Double(dyads[0].harmonies[0].tones[0].frequency[0]), Double(dyads[0].harmonies[0].tones[0].frequency[1]),
                                             Double(dyads[0].harmonies[0].tones[1].frequency[0]), Double(dyads[0].harmonies[0].tones[1].frequency[1]),
                                             Double(dyads[1].harmonies[0].tones[0].frequency[0]), Double(dyads[1].harmonies[0].tones[0].frequency[1]),
                                             Double(dyads[1].harmonies[0].tones[1].frequency[0]), Double(dyads[1].harmonies[0].tones[1].frequency[1])
                ]
                
                let pi = Double.pi
                
                channel_signals[0] = (0..<durationSplits[0]).map { n -> Float32 in
                    var t: Double = scale(min_new: 0.0, max_new: 1.0, val_old: Double(n), min_old: 0.0, max_old: Double(frames))
                    let p: Double = -pi + (tau * (Double(n) / Double(durationSplits[0])))
                    let sinc: Double = 0.5 * cos(pi * t) + cos((pi * t) - p)
                    print("\(n):\t\(p)\t\t\(t)")
                    return Float32(sinc * (sin(tau * frequencies[0] * t))) + Float32((sinc * sin(tau * frequencies[0] * t - p)))
                } + (durationSplits[0]..<frames).map { n -> Float32 in
                    var t: Double = scale(min_new: 0.0, max_new: 1.0, val_old: Double(n), min_old: 0.0, max_old: Double(frames))
                    let p: Double = -pi + (tau * (Double(n) / Double(frames - durationSplits[0])))
                    print("\(n):\t\(p)\t\t\(t)")
                    let sinc: Double = 0.5 * cos(pi * t) + cos((pi * t) - p)
                    return Float32(sinc * (sin(tau * frequencies[1] * t))) + Float32((sinc * sin(tau * frequencies[1] * t - p)))
                }

                channel_signals[1] = (0..<durationSplits[1]).map { n -> Float32 in
                    var t: Double = scale(min_new: 0.0, max_new: 1.0, val_old: Double(n), min_old: 0.0, max_old: Double(frames))
                    let p: Double = -pi + (tau * (Double(n) / Double(durationSplits[1])))
                    let sinc: Double = 0.5 * cos(pi * t) + cos((pi * t) - p)
                    return Float32(sinc * (sin(tau * frequencies[4] * t))) + Float32((sinc * sin(tau * frequencies[5] * t)))
                } + (durationSplits[1]..<frames).map { n -> Float32 in
                    var t: Double = scale(min_new: 0.0, max_new: 1.0, val_old: Double(n), min_old: 0.0, max_old: Double(frames))
                    let p: Double = -pi + (tau * (Double(n) / Double(frames - durationSplits[1])))
                    let sinc: Double = 0.5 * cos(pi * t) + cos((pi * t) - p)
                    return Float32(sinc * (sin(tau * frequencies[6] * t))) + Float32((sinc * sin(tau * frequencies[7] * t)))
                }
                
                //                channel_signals[1] = dyadRanges[1][0].map { n -> Float32 in
                //                                let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                    return Float32(sin(tau * 1280.0 * t) + sin(tau * 1024.0 * t))
                //                            } + dyadRanges[1][1].map { n -> Float32 in
                //                                let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                                return Float32(sin(tau * 550.0 * t) + sin(tau * 750.0 * t))
                //                            }
                
                
                //                channel_signals[0] = dyadRanges[0][0].map { n -> Float32 in
                //                                let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                                return Float32(sin(tau * dyads[0].harmonies[0].tones[0].frequency.0 * t) + sin(tau * dyads[0].harmonies[0].tones[0].frequency.1 * t))
                //                            } + dyadRanges[0][1].map { n -> Float32 in
                //                                let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                                return Float32(sin(tau * dyads[0].harmonies[0].tones[1].frequency.0 * t) + sin(tau * dyads[0].harmonies[0].tones[1].frequency.1 * t))
                //                            }
                //
                //                channel_signals[1] = dyadRanges[1][0].map { n -> Float32 in
                //                                let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                                return Float32(sin(tau * dyads[1].harmonies[0].tones[0].frequency.0 * t) + sin(tau * dyads[1].harmonies[0].tones[0].frequency.1 * t))
                //                            } + dyadRanges[1][1].map { n -> Float32 in
                //                                let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                                return Float32(sin(tau * dyads[1].harmonies[0].tones[1].frequency.0 * t) + sin(tau * dyads[1].harmonies[0].tones[1].frequency.1 * t))
                //                            }
                
                //                channel_signals[0] = dyadRanges[1][0].map { n -> Float32 in
                //                    let t: Double = Double(n) / (Double(bufferLength) - 1.0)
                //                    return Float32(sin(tau * dyads[1].harmonies[0].tones[1].frequency.0 * t))
                //                }.enumerated().map { (index, value) -> Float32 in
                //                    let t: Double = Double(index) / (Double(bufferLength) - 1.0)
                //                    return value + Float32(sin(tau * dyads[1].harmonies[0].tones[1].frequency.1 * t))
                //                }
                //
                //                for n in 0..<number {
                //                    let t: Double = Double(Double(n) / (Double(bufferLength) - 1.0))
                //
                //                    (n >= 0 && n < 20500)
                //                    ? {
                //                        channel_signals[0][n] = Float32(sin(tau * dyads[0].harmonies[0].tones[0].frequency.0 * t) + sin(tau * dyads[0].harmonies[0].tones[0].frequency.1 * t))
                //                        channel_signals[1][n] = Float32(sin(tau * dyads[0].harmonies[1].tones[0].frequency.0 * t) + sin(tau * dyads[0].harmonies[1].tones[0].frequency.1 * t))
                //                    }()
                //                    : {
                //                        channel_signals[0][n] = Float32(sin(tau * dyads[0].harmonies[0].tones[1].frequency.0 * t) + sin(tau * dyads[0].harmonies[0].tones[1].frequency.1 * t))
                //                        channel_signals[1][n] = Float32(sin(tau * dyads[0].harmonies[1].tones[1].frequency.0 * t) + sin(tau * dyads[0].harmonies[1].tones[1].frequency.1 * t))
                //                    }()
                //                }
                
                return {
                    channel_signals
                }
            })
            
            return (audio_buffer[0].makeIterator(), audio_buffer[1].makeIterator())
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
    
    public func generateSignalSamplesIterator(bufferLength: Int) -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
        var tetrad: TetradBuffer.Tetrad = TetradBuffer.Tetrad.init(bufferLength: Int(bufferLength))
        return tetrad.samplesIterator
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
