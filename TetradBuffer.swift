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
import Accelerate

protocol ValueStore {
    var selfPointer: UnsafeMutablePointer<Self>? { get set }
    mutating func store<T>(value: T) -> ()
    func retrieve<T>() -> [T]
}

struct CombinationTones: ValueStore {
    private var selfPointer_ : UnsafeMutablePointer<CombinationTones>?
    var selfPointer: UnsafeMutablePointer<CombinationTones>? {
        get {
            return selfPointer_
        }
        set {
            selfPointer_ = newValue
        }
    }
    
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
    
    init(root: Double) {
        store(value: root)
    }
    
    mutating func store<T>(value: T) -> () {
        if let value = value as? Double {
            self.root             = value
            self.rootUnison       = 1.0 * root
            self.rootPerfectFifth = (5.0 / 4.0) * root
            self.rootOctave       = 2.0 * root
            self.sumUnison        = rootUnison + root
            self.sumPerfectFifth  = rootPerfectFifth + root
            self.sumOctave        = rootOctave + root
            self.diffUnison       = rootUnison - root
            self.diffPerfectFifth = rootPerfectFifth - root
            self.diffOctave       = rootOctave - root
        }
    }
    
    func retrieve<T>() -> [T] {
        return [
            root, rootUnison,   rootPerfectFifth,   rootOctave,
            sumUnison,    sumPerfectFifth,    sumOctave,
            diffUnison,   diffPerfectFifth,   diffOctave
        ] as! [T]
    }
}

func scale(oldMin: Double, oldMax: Double, value: Double, newMin: Double, newMax: Double) -> Double {
    return newMin + ((newMax - newMin) * ((value - oldMin) / (oldMax - oldMin)))
}


class TetradBuffer: NSObject {
    
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
    
    
    public func generateSignalSamplesIterator() -> (Array<Float32>.Iterator, Array<Float32>.Iterator) {
        return tetrad.samplesIterator
    }
    
    public func resetIterator() {
        self.tetrad = Tetrad(bufferLength: bufferLength)
    }
    
    var tetrad: Tetrad
    var bufferLength: Int
    
    init(bufferLength: Int) {
        self.bufferLength = bufferLength
        self.tetrad = Tetrad(bufferLength: bufferLength)
    }
    
    struct Tetrad {
        var dyads: [Dyad]
        
        struct Dyad {
            
            // Example usage
//            var combinationTones: [Double] { CombinationTones(root: 1.0)
//                randomGenerator(randomDistributor: randomDistributor,
//                                distributionRange: 0.0...1.0,
//                                valueTransformer: valueTransformer,
//                                valueStore: &combinationTones)
//                
//                print(combinationTones.retrieve() as [Double])
//            }
            
            
            struct Harmony {
                struct Tone {
                    var frequencies: [Double] {
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
                        var harmonic = root * (5.0 / 4.0)
                        return [root, harmonic]
                    }
                    
                    init() {
                        
                    }
                }
                var tones: [Tone]
                var durationSplit: Int = 44100
                init(durationSplit: Int) {
                    tones = [
                        Tone.init(),
                        Tone.init()
                    ]
                    self.durationSplit = durationSplit
                }
            }
            var harmonies: [Harmony]
            init() {
                harmonies = [
                    Harmony.init(durationSplit: 44100),
                    Harmony.init(durationSplit: 44100),
                ]
            }
        }
        
        var bufferLength: Int = 88200
        var cycleFrames: CycledSequence<Array<Int>>
        var frameIterator: CycledSequence<Array<Int>>.Iterator
        
        init(bufferLength: Int) {
            dyads = [
                Dyad.init(),
                Dyad.init()
            ]
            
            
            
           
//            for value in sineWave {
//                print(value)
//            }

            cycleFrames = Array(0..<bufferLength).cycled()
            frameIterator = cycleFrames.makeIterator()
        }
        
        
            
        public func synthesizeSignal(frequencyAmplitudePairs: [(f: Float32, a: Float32)],
                                     count: Int) -> [Float32] {
            
            let tau: Float32 = Float32.pi * 2
            let signal: [Float32] = (0 ..< count).map { index in
                frequencyAmplitudePairs.reduce(0) { accumulator, frequenciesAmplitudePair in
                    let normalizedIndex = Float32(index) / Float32(count)
                    return accumulator + sin(normalizedIndex * frequenciesAmplitudePair.f * tau) * frequenciesAmplitudePair.a
                }
            }
            
            return signal
        }
        
        


        
//        lo
        
        var samplesIterator: (Array<Float32>.Iterator, Array<Float32>.Iterator) {
//            let n = vDSP_Length(88200)
//            let stride = vDSP_Stride(1)
//
//
//            var a: Float32 = 0.0
//            var b: Float32 = 1.0
//
//             var c = [Float32](repeating: 0,
//                               count: Int(vDSP_Length(88200)))
//            
//            vDSP_vgen(&a,
//                      &b,
//                      &c,
//                      stride,
//                      n)
//            let tau: simd_double1 = simd_double1(simd_double1.pi * 2.0)
//            var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(bufferLength)), Array(repeating: Float32.zero, count: bufferLength)]
            let audio_buffer: [[Float32]] =  ({ (operation: (Int) -> (() -> [[Float32]])) in
                operation(bufferLength)()
            })( { frames in
                let frequencies: [Double] = [Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
                                             Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
                                             Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0]),
                                             Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[0])]
                
//                channel_signals[0] = (Int.zero...44099).map { n -> Float32 in
//                    let t: Double = scale(oldMin: Double.zero, oldMax: 44099, value: Double(n), newMin: Double.zero, newMax: 1.0)
//                    let f: Double = Double(0.125) * (2.0 * sin((sin(tau * frequencies[0] * t)) + (sin(tau * frequencies[1] * t))) * cos((sin(tau * frequencies[0] * t)) - (sin(tau * frequencies[1] * t)))) / 2.0
//                    return Float32(f)
//                } + (44100..<bufferLength).map { n -> Float32 in
//                    let t: Double = scale(oldMin: Double.zero, oldMax: 44099, value: Double(n), newMin: Double.zero, newMax: 1.0)
//                    let f: Double = Double(0.125) * (2.0 * sin((sin(tau * frequencies[2] * t)) + (sin(tau * frequencies[3] * t))) * cos((sin(tau * frequencies[2] * t)) - (sin(tau * frequencies[3] * t)))) / 2.0
//                    return Float32(f)
//                }
//                
//                channel_signals[1] = (Int.zero...44099).map { n -> Float32 in
//                    let t: Double = scale(oldMin: Double.zero, oldMax: 44099, value: Double(n), newMin: Double.zero, newMax: 1.0)
//                    let f: Double = Double(0.125) * (2.0 * sin((sin(tau * frequencies[4] * t)) + (sin(tau * frequencies[5] * t))) * cos((sin(tau * frequencies[4] * t)) - (sin(tau * frequencies[5] * t)))) / 2.0
//                    return Float32(f)
//                } + (44100..<bufferLength).map { n -> Float32 in
//                    let t: Double = scale(oldMin: Double.zero, oldMax: 44099, value: Double(n), newMin: Double.zero, newMax: 1.0)
//                    let f: Double = Double(0.125) * (2.0 * sin((sin(tau * frequencies[6] * t)) + (sin(tau * frequencies[7] * t))) * cos((sin(tau * frequencies[6] * t)) - (sin(tau * frequencies[7] * t)))) / 2.0
//                    return Float32(f)
//                }
                
                
                
//                let frequency: Float32 = (Float32(frequencies[4]) * (2.0 * Float32.pi))
//                
//                var sineWave = [Float32](repeating: 0, count: Int(n))
//                
//                // Calculate sin(2pi * time * frequency)
//                vDSP_vsmul(c, stride, [frequency], &sineWave, stride, n)
//                vvsinf(&sineWave, sineWave, [Int32(n)])
                
                var signal = synthesizeSignal(frequencyAmplitudePairs: [(f: Float32(frequencies[4]), a: (0.25 * Float32.pi))], count: bufferLength)
                
                // Ensure the signal does not cross the Nyquist threshold using a low-pass filter
//                var filterCoefficients: [Double] = [Double]([0.1, 0.15, 0.5, 0.15])
//                var delay = [Float32](repeating: 0.0, count: 4)
//                var setup = vDSP_biquad_CreateSetup(&filterCoefficients, vDSP_Length(bufferLength)) //vDSP_biquad_CreateSetup(&filterCoefficients, vDSP_Length(bufferLength))
//
//                
//                var filteredSignal = [Float32](repeating: 0.0, count: bufferLength)
//                
//                vDSP_biquad((&setup)!, &delay, &signal, 1, &filteredSignal, 1, vDSP_Length(bufferLength))
//                
//                vDSP_biquad_DestroySetup(setup)
//                
                return {
                    //                    channel_signals
                    [signal, signal]
                }
            })
            
            return (audio_buffer[0].makeIterator(), audio_buffer[1].makeIterator())
        }
    }
}
