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

// Define the ValueStore protocol
protocol ValueStore {
    var selfPointer: UnsafeMutablePointer<Self>? { get set }
    mutating func store<T>(value: T) -> ()
    func retrieve<T>() -> [T]
}

// Updated CombinationTones struct conforming to ValueStore protocol
struct CombinationTones: ValueStore {
    private var root:             Double = .zero // root
    private var rootUnison:       Double = .zero // 1 * root
    private var rootPerfectFifth: Double = .zero // 5/4 * root
    private var rootOctave:       Double = .zero // 2 * root
    private var sumUnison:        Double = .zero // rootUnison + root
    private var sumPerfectFifth:  Double = .zero // rootPerfectFifth + root
    private var sumOctave:        Double = .zero // rootOctave + root
    private var diffUnison:       Double = .zero // rootUnison - root
    private var diffPerfectFifth: Double = .zero // rootPerfectFifth - root
    private var diffOctave:       Double = .zero // rootOctave - root
    
    var selfPointer: UnsafeMutablePointer<CombinationTones>?

    
    init(root: Double) {
        store(value: root)
    }
    
    mutating func store<T>(value: T) -> () {
        if let value = value as? Double {
            self.root             = value
            self.rootUnison       = 1.0 * root
            self.rootPerfectFifth = (5.0 / 4.0) * root
            self.rootOctave       = 2 * root
            self.sumUnison        = rootUnison + root
            self.sumPerfectFifth  = rootPerfectFifth + root
            self.sumOctave        = rootOctave + root
            self.diffUnison       = rootUnison - root
            self.diffPerfectFifth = rootPerfectFifth - root
            self.diffOctave       = rootOctave - root
        }
        selfPointer = { UnsafeMutablePointer(&self) }()
    }
    
    func retrieve<T>() -> [T] {
        return [
            root, rootUnison, rootPerfectFifth, rootOctave,
            sumUnison, sumPerfectFifth, sumOctave,
            diffUnison, diffPerfectFifth, diffOctave
        ] as! [T]
    }
}

let randomDistributor: (Double) -> Double = { value in
    return pow(value, 1.0 / 3.0)
}

let valueTransformer: (Double) -> Double = { c in
    let f: Double = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
    return f
}

func randomGenerator<T: ValueStore>(randomDistributor: @escaping (Double) -> Double,
                                    distributionRange: ClosedRange<Double>,
                                    valueTransformer: @escaping (Double) -> Double,
                                    valueStore: inout T) {
    let randomValue = Double.random(in: distributionRange)
    let distributedValue = randomDistributor(randomValue)
    let transformedValue = valueTransformer(distributedValue)
    valueStore.store(value: transformedValue)
}

//// Example usage
//var combinationTones: [Double] { CombinationTones(root: 1.0)
//    randomGenerator(randomDistributor: randomDistributor,
//                    distributionRange: 0.0...1.0,
//                    valueTransformer: valueTransformer,
//                    valueStore: &combinationTones)
//
//    print(combinationTones.retrieve() as [Double])
//}
//
//// Example usage
//var combinationTones = CombinationTones(root: 1.0)
//randomGenerator(randomDistributor: randomDistributor,
//                distributionRange: 0.0...1.0,
//                valueTransformer: valueTransformer,
//                valueStore: &combinationTones)
//
//print(combinationTones.retrieve() as [Double])

// Example usage
//var combinationTones = CombinationTones(root: 1.0)
//randomGenerator(randomDistributor: randomDistributor,
//                distributionRange: 0.0...1.0,
//                valueTransformer: valueTransformer,
//                valueStore: &combinationTones)
//
//print(combinationTones.retrieve() as [Double])



func scale(oldMin: Double, oldMax: Double, value: Double, newMin: Double, newMax: Double) -> Double {
    return newMin + ((newMax - newMin) * ((value - oldMin) / (oldMax - oldMin)))
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
    
    func standardizedRandom() -> Double {
        return Double.zero
    }
    
    //    func pianoNoteFrequency() -> Double {
    //        let c: Double = Double.random(in: (0.5...1.0))
    //        let f: Double = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
    //        return f
    //    }
    
    
    /*
     
     var noteFrequency = NoteFrequency(value: 440.0)
     
     // Accessing values
     print("Stored Root: \(noteFrequency.storedRoot)")
     print("Stored Octave: \(noteFrequency.storedOctave)")
     print("Stored Harmonic: \(noteFrequency.storedHarmonic)")
     
     // Modifying values via pointers
     withUnsafeMutablePointer(to: &noteFrequency.storedRoot) { $0.pointee = 220.0 }
     withUnsafeMutablePointer(to: &noteFrequency.storedOctave) { $0.pointee = 440.0 }
     withUnsafeMutablePointer(to: &noteFrequency.storedHarmonic) { $0.pointee = 293.33 }
     
     print("Modified Stored Root: \(noteFrequency.storedRoot)")
     print("Modified Stored Octave: \(noteFrequency.storedOctave)")
     print("Modified Stored Harmonic: \(noteFrequency.storedHarmonic)")
     
     */
    
    /*
     
     let note_frequencies  = store_note_frequency()
     var combination_notes = note_frequencies(pianoNoteFrequency())
     
     */
    
    // Tetrad will generate harmonic intervals for tones. It will decide the key, the scale, tonality or atonality, consonance or dissonance, etc.
    // It will also generate the duration splits, which will contain a value for adding tremolo and trill effects to the tones. There are two types of trills:
    // *Augmented* Intervals are wider by one semitone (half-step) than perfect or major intervals.
    // *Diminished Intervals* are smaller by one semitone (half-step) than perfect or minor intervals.
    // Trills modulates frequency
    // Tremolo modulates amplitude
    struct Tetrad {
        struct Dyad {
            struct Harmony {
                struct Tone {
                    // Tessitura : The general range of pitches found in a melody
                    // Tremolo : Quick repetition of the same note or the rapid alternation between two notes.
                    // Trill: Trill is an instruction to sustain rapid alternation between two different pitches.
                    // Vibrato ; Vibrato is an effect where the pitch of a note is subtly moved up and down to create a vibrating effec
                    var frequencies: [Double] {
                        let frequencyLowerBound = 400.0
                        let frequencyUpperBound = 3000.0
                        let threshold = 2000.0
                        let probabilityThreshold = 1600.0 / 3600.0
                        
                        // Root : The fundamental pitch on which a chord is based
                        var root: Double = {
                            if Double.random(in: 0.0..<1.0) > probabilityThreshold {
                                return Double.random(in: threshold...frequencyUpperBound)
                            } else {
                                return Double.random(in: frequencyLowerBound..<threshold)
                            }
                        }()
                        var harmonic = root * (5.0 / 4.0) //* key
                        return [root, harmonic]
                    }
                    
                    init() {
                        
                    }
                }
                var tones: [Tone]
                
                init() {
                    tones = [
                        Tone.init(),
                        Tone.init()
                    ]
                }
            }
            var harmonies: [Harmony]
            init() {
                harmonies = [
                    Harmony.init(),
                    Harmony.init(), // Pivot Chord: Used for a smooth modulation, it is a chord that is common to the current key, and the one being modulated into.
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
                //
                //                // Methods to my madness:
                //                //Syncopation  : A disturbance or interruption of the regular flow of downbeat rhythm with emphasis on the subdivision or off-beat.
                //                // Oblique motion: The movement of two melodic lines where one voice is stationary as the other voice moves in either direction (vs. parallel motion)
                //                // Parallel 5ths and Parallel Octaves are gentle ways of adding caucophony to chords without resorting to the harsher dissonant mismatch
                //                // Pedal Point: A sustained note during which the harmony above it changes in some way so that the overall sound becomes dissonant.
                //                // Polyrhythm: A rhythm that makes use of two or more different rhythms simultaneously.
                //
                let frequencies: [Double] = [Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
                                             Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
                                             Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
                                             Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0])]
                //
                let pi = Double.pi
                //
                                channel_signals[0] = (0..<44100).map { n -> Float32 in
                                    let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
                                    let t: Double = scale(oldMin: 0.0, oldMax: 44099, value: Double(n), newMin: 0.0, newMax: 1.0)
                                    let a: Double = sin(pi * t) * sin(tau * frequencies[0] * t)
                                    let b: Double = sin(pi * t) * sin(tau * frequencies[1] * t)
                                    let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
                                    return Float32(f)
                                } + (44100..<frames).map { n -> Float32 in
                                    let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
                                    let t: Double = scale(oldMin: 0.0, oldMax: Double(frames) - 44100, value: Double(n), newMin: 0.0, newMax: 1.0)
                                    let a: Double = sin(pi * t) * sin(tau * frequencies[2] * t)
                                    let b: Double = sin(pi * t) * sin(tau * frequencies[3] * t)
                                    let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
                                    return Float32(f)
                                }
                //
                                channel_signals[1] = (0..<44100).map { n -> Float32 in
                                    let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
                                    let t: Double = scale(oldMin: 0.0, oldMax: 44099, value: Double(n), newMin: 0.0, newMax: 1.0)
                                    let a: Double = sin(pi * t) * sin(tau * frequencies[4] * t)
                                    let b: Double = sin(pi * t) * sin(tau * frequencies[5] * t)
                                    let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
                                    return Float32(f)
                                } + (44100..<frames).map { n -> Float32 in
                                    let s: Double = scale(oldMin: 0.0, oldMax: (Double(frames) / Double(bufferLength)), value: (Double(n) / Double(frames)), newMin: 0.0, newMax: 1.0)
                                    let t: Double = scale(oldMin: 0.0, oldMax: Double(frames) - 44100, value: Double(n), newMin: 0.0, newMax: 1.0)
                                    let a: Double = sin(pi * t) * sin(tau * frequencies[6] * t)
                                    let b: Double = sin(pi * t) * sin(tau * frequencies[7] * t)
                                    let f: Double = (2.0 * sin(a + b) * cos(a - b)) / 2.0
                                    return Float32(f)
                                }
                
                return {
                    channel_signals
                }
            })
            
            return (audio_buffer[0].makeIterator(), audio_buffer[1].makeIterator())
        }
        
        var duration_splits: [[[Int]]] {
            var durations: [[[Double]]] = [
                [Array(repeating: Double.zero, count: Int(2)), Array(repeating: Double.zero, count: Int(2))],
                [Array(repeating: Double.zero, count: Int(2)), Array(repeating: Double.zero, count: Int(2))]
            ]
            var durationOp: [[[Double]]] = ({ (operation: (Int) -> (() -> [[[Double]]])) in
                operation(bufferLength)()
            })( { frames in
                let a: Double = 2.0000
                let b: Double = scale(oldMin: 0.3125, oldMax: 1.6875, value: 0.3125, newMin: 0.0, newMax: 1.0) // 0.00000
                let c: Double = scale(oldMin: 0.3125, oldMax: 1.6875, value: 1.6875, newMin: 0.0, newMax: 1.0) // 1.00000
                let d: Double = scale(oldMin: 0.0000, oldMax: 2.0000, value: 0.3125, newMin: 0.0, newMax: 1.0) // 0.15625
                
                let r: ClosedRange<Double> = (b...c)
                
                for i in (0...3) {
                    durations[i] = (0..<2).map { n -> [Double] in
                        let q: Double = Double.random(in: r)
                        
                        var validRanges: [ClosedRange<Double>] = []
                        
                        let down = q - d
                        if (b <= down) {
                            let downRange = b...down
                            validRanges.append(r.clamped(to: downRange))
                        }
                        
                        let up = q + d
                        if (up <= c) {
                            let upRange = up...c
                            validRanges.append(r.clamped(to: upRange))
                        }
                        
                        let range = validRanges.randomElement()!
                        let r: Double = Double.random(in: range)
                        
                        return [(q < r) ? q : r, (q < r) ? r : q]
                    }
                }
                
                return {
                    durations
                }
            })
            return []
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
}

public func generateSignalSamplesIterator(bufferLength: Int) -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
    var tetrad: TetradBuffer.Tetrad = TetradBuffer.Tetrad.init(bufferLength: Int(bufferLength))
    return tetrad.samplesIterator
}
