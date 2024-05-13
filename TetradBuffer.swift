//
//  TetradBuffer.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 5/12/24.
//

import Foundation

class TetradBuffer {
    struct Tetrad {
        struct Dyad {
            struct Harmony {
                struct Tone {
                    var frequency: Double = Double.zero
                }
                var duration: Double
                var tones: [Tone]
                init(duration: Double) {
                    self.duration = duration
                    let frequencies: (Double, Double) = {
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
                        let harmonic: Double = root * (5.0 / 4.0)
                        
                        return (root, harmonic)
                    }()
                    tones = [
                        Tone.init(frequency: frequencies.0),
                        Tone.init(frequency: frequencies.1)
                    ]
                }
            }
            var harmonies: [Harmony]
            init() {
                let durations: (Double, Double) = {
                    let lowerBound = 0.3125
                    let upperBound = 1.6875
                    let secondDuration = (2.0 - Double.random(in: lowerBound..<upperBound))
                    let firstDuration = (2.0 - secondDuration)
                    
                    // Ensure the difference between durations is greater than 0.3125
                    //        while abs(firstDuration - secondDuration) <= 0.3125 {
                    //            secondDuration = Float32(round(10000 * Double.random(in: lowerBound...upperBound)) / 10000)
                    //        }
                    return (Double(firstDuration), Double(secondDuration))
                }()
                harmonies = [
                    Harmony.init(duration: durations.0),
                    Harmony.init(duration: durations.1)]
            }
        }
        var dyads: [Dyad]
        init() {
            dyads = [
                Dyad.init(),
                Dyad.init()]
        }
    }
    
    func generateTetrad() -> Tetrad {
        let tetrad: Tetrad = Tetrad.init()
        var str: String = "Tetrad\n"
        for i in (0...1) {
            str = str + "\tDyad \(i + 1)\n"
            for j in (0...1) {
                str = str + "\t\tHarmony \(j + 1)" + "\t\tduration     = \(tetrad.dyads[i].harmonies[j].duration)\n"
                for k in (0...1) {
                    str = str + "\t\t\tTone \(k + 1)" + "\t\t\tfrequency = \(tetrad.dyads[i].harmonies[j].tones[k].frequency)\n"
                }
            }
        }
        print(str)
        return tetrad
    }
}
