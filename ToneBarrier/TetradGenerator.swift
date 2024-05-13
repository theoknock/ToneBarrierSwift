//
//  TetradGenerator.swift
//  ToneBarrierDurationGenerator
//
//  Created by James Alan Bush on 5/11/24.
//

import Foundation

// Static properties
let durationSum: Double = 2.0
let durationRange       = 0.3125...1.6875
let frequencyRange      = 1000.0...4000.0
let trillRange          = 2.0...8.0
let tremoloRange        = 2.0...8.0

let combinedSinusoid = 0.5 * sin(2 * .pi * time * frequency) + 0.5 * sin(2 * .pi * time * frequency)

//
//struct Tone {
//    var frequency: Double
//}
//
//struct Harmony {
//    var tones: [Tone] = toneFrequencies()
//    var durations: (Double, Double) = (Double.zero, Double.zero)
//    
//    func toneFrequencies() -> [Tone] {
//        return [Tone(frequency: Double.zero), Tone(frequency: Double.zero)]
//    }
//}
//
//struct Dyad {
//    var harmonies: [Harmony]
//    
//    func harmonyDurations() -> (Double, Double) {
//        return 1.0
//    }
//    
//    var dyadBuffer: [[Float32]]
//}
//
//struct Tetrad {
//    init(dyads: [Dyad], tetradBuffer: [[Float32]], bufferLength: UInt32) {
//        self.dyads = dyads
//        self.tetradBuffer = tetradBuffer
//        self.bufferLength = bufferLength
//    }
//    
//    var dyads: [Dyad]
//    
//    func additiveSynthesis(sinusoids: (Double, Double)) -> Double {
//        return 1.0
//    }
//    
//    var tetradBuffer: [[Float32]]
//    var bufferLength: UInt32
//}
//
//class TetradGenerator {
//    func generateDistinctDurations() -> (Float32, Float32) {
//        let lowerBound = 0.3125
//        let upperBound = 1.6875
//        let firstDuration = Float32(round(10000 * Double.random(in: lowerBound...upperBound)) / 10000)
//        var secondDuration = Float32(round(10000 * Double.random(in: lowerBound...upperBound)) / 10000)
//        
//        // Ensure the difference between durations is greater than 0.3125
//        while abs(firstDuration - secondDuration) <= 0.3125 {
//            secondDuration = Float32(round(10000 * Double.random(in: lowerBound...upperBound)) / 10000)
//        }
//        
//        return (Float32(firstDuration), Float32(secondDuration))
//    }
//    
//    func additiveSynthesis(sinusoids: (Double, Double)) -> Double {
//        
//    }
//    
//    func generateFrequencies() -> (Float32, Float32) {
//        let frequencyLowerBound = 400.0  // Lower frequency limit
//        let frequencyUpperBound = 3000.0  // Upper frequency limit
//        let threshold = 2000.0  // Threshold for higher frequency range
//        let probabilityThreshold = 1600.0 / 3600.0  // Probability of frequency above 2000 Hz
//            
//        var tone1: Float32 = Float32({
//            if Double.random(in: 0..<1) > probabilityThreshold {
//                // Generate frequency above 2000 Hz
//                return Float32(Double.random(in: threshold...frequencyUpperBound))
//            } else {
//                // Generate frequency from 400 Hz to just below 2000 Hz
//                return Float32(Double.random(in: frequencyLowerBound..<threshold))
//            }
//        }())
//        
//        var tone2: Float32 = tone1
//        
////        Float32({
////            if Double.random(in: 0..<1) > probabilityThreshold {
////                // Generate frequency above 2000 Hz
////                return Float32(Double.random(in: threshold...frequencyUpperBound))
////            } else {
////                // Generate frequency from 400 Hz to just below 2000 Hz
////                return Float32(Double.random(in: frequencyLowerBound..<threshold))
////            }
////        }())
//        
////        while abs(tone1 - tone2) <= 400.0 {
////            tone2 = Float32({
////                if Double.random(in: 0..<1) > probabilityThreshold {
////                    // Generate frequency above 2000 Hz
////                    return Float32(Double.random(in: threshold...frequencyUpperBound))
////                } else {
////                    // Generate frequency from 400 Hz to just below 2000 Hz
////                    return Float32(Double.random(in: frequencyLowerBound..<threshold))
////                }
////            }())
////        }
//        
//            return (tone1, tone2)
//        }
//    
//    func generateTetrad() -> Tetrad {
//        let (firstHarmonyDuration, secondHarmonyDuration) = generateDistinctDurations()
//        let dyad1 = Dyad(
//            harmonies: [
//                Harmony(tones: [Tone(duration: round(10000 * firstHarmonyDuration) / 10000), Tone(duration: round(10000 * firstHarmonyDuration) / 10000)]),
//                Harmony(tones: [Tone(duration: round(10000 * (2.0 - firstHarmonyDuration)) / 10000), Tone(duration: round(10000 * (2.0 - firstHarmonyDuration)) / 10000)])
//            ]
//        )
//        
//        let dyad2 = Dyad(
//            harmonies: [
//                Harmony(tones: [Tone(duration: round(10000 * secondHarmonyDuration) / 10000), Tone(duration: round(10000 * secondHarmonyDuration) / 10000)]),
//                Harmony(tones: [Tone(duration: round(10000 * (2.0 - secondHarmonyDuration)) / 10000), Tone(duration: round(10000 * (2.0 - secondHarmonyDuration)) / 10000)])
//            ]
//        )
//        
//        return Tetrad(dyads: [dyad1, dyad2])
//    }
//}
