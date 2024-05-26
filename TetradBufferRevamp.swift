
//public func generateSignalSamplesIterator(bufferLength: Int) -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
//    var tetrad: TetradBuffer.Tetrad = TetradBuffer.Tetrad.init(bufferLength: Int(bufferLength))
//    return tetrad.samplesIterator
//}


//var duration_splits:  [[(Double, Double)]] {
//    var durations: [[(Double, Double)]] = [
//        [(Double.zero, Double.zero)], [(Double.zero, Double.zero)],
//        [(Double.zero, Double.zero)], [(Double.zero, Double.zero)]
//    ]
//    
//    func scale(oldMin: Double, oldMax: Double, value: Double, newMin: Double, newMax: Double) -> Double {
//        return ((value - oldMin) / (oldMax - oldMin)) * (newMax - newMin) + newMin
//    }
//    
//    var durationOp: [[(Double, Double)]] = ({ (operation: (Int) -> (() -> [[(Double, Double)]])) in
//        operation(bufferLength)()
//    })({ frames in
//        let a: Double = 2.0000
//        let b: Double = scale(oldMin: 0.3125, oldMax: 1.6875, value: 0.3125, newMin: 0.0, newMax: 1.0)
//        let c: Double = scale(oldMin: 0.3125, oldMax: 1.6875, value: 1.6875, newMin: 0.0, newMax: 1.0)
//        let d: Double = scale(oldMin: 0.0000, oldMax: 2.0000, value: 0.3125, newMin: 0.0, newMax: 1.0)
//        
//        let r: ClosedRange<Double> = (b...c)
//        
//        for i in 0..<2 {
//            durations[i] = (0..<2).map { _ -> (Double, Double) in
//                let q: Double = Double.random(in: r)
//                
//                var validRanges: [ClosedRange<Double>] = []
//                
//                let down = q - d
//                if b <= down {
//                    let downRange = b...down
//                    validRanges.append(r.clamped(to: downRange))
//                }
//                
//                let up = q + d
//                if up <= c {
//                    let upRange = up...c
//                    validRanges.append(r.clamped(to: upRange))
//                }
//                
//                let range = validRanges.randomElement()!
//                let r: Double = Double.random(in: range)
//                
//                return [r, q].minAndMax() ?? (0.5, 0.5)
//            }
//        }
//        
//        return {
//            durations
//        }
//    })
//    
//    return durationOp
//}
//}
//
//////
//////  TetradBuffer.swift
//////  ToneBarrier
//////
//////  Created by Xcode Developer on 5/12/24.
//////
////
////import Foundation
////import AVFoundation
////import AVFAudio
////import Algorithms
////
////
//////func randomFrequency() -> Double {
//////    return Double.random(in: 440.0...3000.0)
//////}
////
////class ToneScore {
////    
////    struct Tone {
////        var frequency: Double
////        var amplitude: Double
////        
////        init(frequency: Double, amplitude: Double) {
////            self.frequency = frequency
////            self.amplitude = amplitude
////        }
////    }
////    
////    struct Harmony {
////        var duration: Double
////        var amplitude: Double
////        
////        init(duration: Double, amplitude: Double) {
////            self.duration  = duration
////            self.amplitude = amplitude
////        }
////    }
////    
////    struct Dyad {
////        var amplitude: Double
////        
////        init(amplitude: Double) {
////            self.amplitude = amplitude
////        }
////    }
////    
////   struct Tetrad {
////        var dyads: [Dyad]
////        var Harmony: [Harmony]
////    }
////}
////
//////struct Harmony {
//////    var frequencies: [Double] {
//////        let frequencyLowerBound = 400.0
//////        let frequencyUpperBound = 3000.0
//////        let threshold = 2000.0
//////        let probabilityThreshold = 1600.0 / 3600.0
//////        var root: Double = {
//////            if Double.random(in: 0.0..<1.0) > probabilityThreshold {
//////                return Double.random(in: threshold...frequencyUpperBound)
//////            } else {
//////                return Double.random(in: frequencyLowerBound..<threshold)
//////            }
//////        }()
//////        var harmonic = root * (5.0 / 4.0)
//////        return [root, harmonic]
//////    }
//////    
//////    var tones: [Tone]
//////    init() {
//////        tones = [
//////            Tone.init(),
//////            Tone.init()
//////        ]
//////    }
//////}
//////
//////struct Dyad {
//////    var harmonies: [Harmony]
//////    init() {
//////        harmonies = [
//////            Harmony.init(),
//////            Harmony.init(), // Pivot Chord: Used for a smooth modulation, it is a chord that is common to the current key, and the one being modulated into.
//////        ]
//////    }
//////}
////
////// Initializes all data structures using outside functions (modules)
////struct Tetrad {
////    
////    var dyads: [Dyad]
////    var bufferLength: Int = 88200
////    var cycleFrames: CycledSequence<Array<Int>>
////    var frameIterator: CycledSequence<Array<Int>>.Iterator
////    
////    var samplesIterator: (Array<Float32>.Iterator, Array<Float32>.Iterator) {
////        let tau: Double =  Double(Double.pi * 2.0)
////        var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(bufferLength)), Array(repeating: Float32.zero, count: bufferLength)]
////        let audio_buffer: [[Float32]] =  ({ (operation: (Int) -> (() -> [[Float32]])) in
////            operation(bufferLength)()
////        })( { frames in
////            let frequencies: [Double] = [Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
////                                         Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
////                                         Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
////                                         Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0])]
////            let pi = Double.pi
////            channel_signals[0] = (0..<44100).map { n -> Float32 in
////                let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
////                let t: Double = scale(oldMin: 0.0, oldMax: 44099, value: Double(n), newMin: 0.0, newMax: 1.0)
////                let a: Double = sin(pi * t) * sin(tau * frequencies[0] * t)
////                let b: Double = sin(pi * t) * sin(tau * frequencies[1] * t)
////                let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
////                return Float32(f)
////            } + (44100..<frames).map { n -> Float32 in
////                let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
////                let t: Double = scale(oldMin: 0.0, oldMax: Double(frames) - 44100, value: Double(n), newMin: 0.0, newMax: 1.0)
////                let a: Double = sin(pi * t) * sin(tau * frequencies[2] * t)
////                let b: Double = sin(pi * t) * sin(tau * frequencies[3] * t)
////                let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
////                return Float32(f)
////            }
////            channel_signals[1] = (0..<44100).map { n -> Float32 in
////                let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
////                let t: Double = scale(oldMin: 0.0, oldMax: 44099, value: Double(n), newMin: 0.0, newMax: 1.0)
////                let a: Double = sin(pi * t) * sin(tau * frequencies[4] * t)
////                let b: Double = sin(pi * t) * sin(tau * frequencies[5] * t)
////                let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
////                return Float32(f)
////            } + (44100..<frames).map { n -> Float32 in
////                let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
////                let t: Double = scale(oldMin: 0.0, oldMax: Double(frames) - 44100, value: Double(n), newMin: 0.0, newMax: 1.0)
////                let a: Double = sin(pi * t) * sin(tau * frequencies[6] * t)
////                let b: Double = sin(pi * t) * sin(tau * frequencies[7] * t)
////                let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
////                return Float32(f)
////            }
////            
////            return {
////                channel_signals
////            }
////        })
////        
////        return (audio_buffer[0].makeIterator(), audio_buffer[1].makeIterator())
////    }
////    
////    var duration_splits:  [[(Double, Double)]] {
////        var durations: [[(Double, Double)]] = [
////            [(Double.zero, Double.zero)], [(Double.zero, Double.zero)],
////            [(Double.zero, Double.zero)], [(Double.zero, Double.zero)]
////        ]
////        
////        func scale(oldMin: Double, oldMax: Double, value: Double, newMin: Double, newMax: Double) -> Double {
////            return ((value - oldMin) / (oldMax - oldMin)) * (newMax - newMin) + newMin
////        }
////        
////        func scale_deg(oldMin: Double, oldMax: Double, value: Double, newMin: Double, newMax: Double) -> Double {
////            return ((Angle(degrees: value) - Angle(degrees: oldMin)) / (Angle(degrees: oldMax) - Angle(degrees: oldMin))) * (Angle(degrees: newMax) - Angle(degrees: newMin)) + Angle(degrees: newMin)
////        }
////        
////        var durationOp: [[(Double, Double)]] = ({ (operation: (Int) -> (() -> [[(Double, Double)]])) in
////            operation(bufferLength)()
////        })({ frames in
////            let a: Double = 2.0000
////            let b: Double = scale(oldMin: 0.3125, oldMax: 1.6875, value: 0.3125, newMin: 0.0, newMax: 1.0)
////            let c: Double = scale(oldMin: 0.3125, oldMax: 1.6875, value: 1.6875, newMin: 0.0, newMax: 1.0)
////            let d: Double = scale(oldMin: 0.0000, oldMax: 2.0000, value: 0.3125, newMin: 0.0, newMax: 1.0)
////            
////            let r: ClosedRange<Double> = (b...c)
////            
////            for i in 0..<2 {
////                durations[i] = (0..<2).map { _ -> (Double, Double) in
////                    let q: Double = Double.random(in: r)
////                    
////                    var validRanges: [ClosedRange<Double>] = []
////                    
////                    let down = q - d
////                    if b <= down {
////                        let downRange = b...down
////                        validRanges.append(r.clamped(to: downRange))
////                    }
////                    
////                    let up = q + d
////                    if up <= c {
////                        let upRange = up...c
////                        validRanges.append(r.clamped(to: upRange))
////                    }
////                    
////                    let range = validRanges.randomElement()!
////                    let r: Double = Double.random(in: range)
////                    
////                    return [r, q].minAndMax() ?? (0.5, 0.5)
////                }
////            }
////            
////            return {
////                durations
////            }
////        })
////        
////        return durationOp
////    }
////    
////    init(bufferLength: Int) {
////        dyads = [
////            Dyad.init(),
////            Dyad.init()
////        ]
////        
////    }
////    
////    
////    
////    //        cycleFrames = Array(0..<bufferLength).cycled()
////    //        frameIterator = cycleFrames.makeIterator()
////}
////
////class TetradBufferRevamp {
////    
////    var tetrad: Tetrad
////    var bufferLength: Int
////    
////    init(bufferLength: Int) {
////        self.bufferLength = bufferLength
////        self.tetrad = Tetrad(bufferLength: bufferLength)
////    }
////    
////    public func generateSignalSamplesIterator() -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
////        return tetrad.samplesIterator
////    }
////    
////    public func resetIterator() {
////        self.tetrad = Tetrad(bufferLength: bufferLength)
////    }
////    
////    func standardizedRandom() -> Double {
////        return Double.zero
////    }
////    
////
////}
////
////public func generateSignalSamplesIterator(bufferLength: Int) -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
////    var tetrad: TetradBuffer.Tetrad = TetradBuffer.Tetrad.init(bufferLength: Int(bufferLength))
////    return tetrad.samplesIterator
////}
//
//
//
//
////    func pianoNoteFrequency() -> Double {
////        let c: Double = Double.random(in: (0.5...1.0))
////        let f: Double = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
////        return f
////    }
//
//
///*
// 
// var noteFrequency = NoteFrequency(value: 440.0)
// 
// // Accessing values
// print("Stored Root: \(noteFrequency.storedRoot)")
// print("Stored Octave: \(noteFrequency.storedOctave)")
// print("Stored Harmonic: \(noteFrequency.storedHarmonic)")
// 
// // Modifying values via pointers
// withUnsafeMutablePointer(to: &noteFrequency.storedRoot) { $0.pointee = 220.0 }
// withUnsafeMutablePointer(to: &noteFrequency.storedOctave) { $0.pointee = 440.0 }
// withUnsafeMutablePointer(to: &noteFrequency.storedHarmonic) { $0.pointee = 293.33 }
// 
// print("Modified Stored Root: \(noteFrequency.storedRoot)")
// print("Modified Stored Octave: \(noteFrequency.storedOctave)")
// print("Modified Stored Harmonic: \(noteFrequency.storedHarmonic)")
// 
// */
//
///*
// 
// let note_frequencies  = store_note_frequency()
// var combination_notes = note_frequencies(pianoNoteFrequency())
// 
// */
//
//// Tetrad will generate harmonic intervals for tones. It will decide the key, the scale, tonality or atonality, consonance or dissonance, etc.
//// It will also generate the duration splits, which will contain a value for adding tremolo and trill effects to the tones. There are two types of trills:
//// *Augmented* Intervals are wider by one semitone (half-step) than perfect or major intervals.
//// *Diminished Intervals* are smaller by one semitone (half-step) than perfect or minor intervals.
//// Trills modulates frequency
//// Tremolo modulates amplitude
//
//// Pivot Chord: Used for a smooth modulation, it is a chord that is common to the current key, and the one being modulated into.
//
////        func sineWaveValue(time t: Double, duration: Double, baseFrequency f1: Double, trillFrequency f2: Double, initialTrillRate: Double, trillDecay: Double, initialTremoloRate: Double, tremoloDepth: Double, tremoloDecay: Double) -> Double {
////            // Calculate the decreasing trill rate over time
////            let trillRate = initialTrillRate * simd.exp(-trillDecay * t)
////            let trillPeriod = 1 / trillRate
////            let trillTime = fmod(t, trillPeriod) / trillPeriod
////            let f = f1 + (f2 - f1) * simd.sin(trillTime * 2 * simd_double1.pi)
////
////            // Calculate the decreasing tremolo rate over time
////            let tremoloRate = initialTremoloRate * simd.exp(-tremoloDecay * t)
////            let tremolo = 1.0 - tremoloDepth + tremoloDepth * simd.sin(2 * simd_double1.pi * t * tremoloRate)
////
////            // Calculate the amplitude envelope with a linear fade-out
////            let amplitudeDecayRate = 1.0 / duration
////            let A = max(0.0, (1.0 - amplitudeDecayRate * t) * tremolo) // Ensures amplitude doesn't go below 0
////
////            // Calculate the sine wave value with the current frequency and amplitude
////            let value = A * simd.sin(2 * simd_double1.pi * t * f)
////
////            return value
////        }
//
//
//// Tessitura : The general range of pitches found in a melody
//// Tremolo : Quick repetition of the same note or the rapid alternation between two notes.
//// Trill: Trill is an instruction to sustain rapid alternation between two different pitches.
//// Vibrato ; Vibrato is an effect where the pitch of a note is subtly moved up and down to create a vibrating effec
//
