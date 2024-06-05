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

// Example usage
//            var combinationTones: [Double] { CombinationTones(root: 1.0)
//                randomGenerator(randomDistributor: randomDistributor,
//                                distributionRange: 0.0...1.0,
//                                valueTransformer: valueTransformer,
//                                valueStore: &combinationTones)
//
//                print(combinationTones.retrieve() as [Double])
//            }

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
            var durations: [Int] = [Int.zero, Int.zero]
            struct Harmony {
                struct Tone {
                    
                    var frequencies: [Double] {
                        let root: Double = {
                            let c: Double = Double.random(in: (0.5...1.0))
                            let f: Double = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
                            
                            return f
                        }()
                        let harmonic = root * (5.0 / 4.0)
                        
                        return [root, harmonic]
                    }
                    
                    init() {
                        
                    }
                }
                var tones: [Tone]
                var duration: Int = 44100
                init(duration: Int) {
                    tones = [
                        Tone.init(),
                        Tone.init()
                    ]
                    self.duration = duration
                }
            }
            var harmonies: [Harmony]
            init(durations: [Int]) {
                self.durations = durations
                harmonies = [
                    Harmony.init(duration: durations[0]),
                    Harmony.init(duration: durations[1]),
                ]
            }
        }
        
        var bufferLength: Int = 88200
        var cycleFrames: CycledSequence<Array<Int>>
        var frameIterator: CycledSequence<Array<Int>>.Iterator
//        var randoms: [Int]  {
//            var circularDistributor: CircularLatticeDistribution = CircularLatticeDistribution(boundLower: 0.0625, boundUpper: 0.9375, threshholdLeft: 0.0625, threshholdRight: 0.0625)
//            return [Int(circularDistributor.randoms[0] * Float64(bufferLength)), Int(circularDistributor.randoms[1] * Float64(bufferLength))]
//        }
        
        
        init(bufferLength: Int) {
            self.bufferLength = bufferLength
            
            dyads = [
                Dyad.init(durations: {
                    var circularDistributor: CircularLatticeDistribution = CircularLatticeDistribution(boundLower: 0.0625, boundUpper: 0.9375, threshholdLeft: 0.0625, threshholdRight: 0.0625)
                    return [Int(circularDistributor.randoms[0] * Float64(bufferLength)), Int(circularDistributor.randoms[1] * Float64(bufferLength))]
                }()),
                Dyad.init(durations: {
                    var circularDistributor: CircularLatticeDistribution = CircularLatticeDistribution(boundLower: 0.0625, boundUpper: 0.9375, threshholdLeft: 0.0625, threshholdRight: 0.0625)
                    return [Int(circularDistributor.randoms[0] * Float64(bufferLength)), Int(circularDistributor.randoms[1] * Float64(bufferLength))]
                }())
            ]
            
            
            
            
            //            for value in sineWave {
            //                print(value)
            //            }
            
            cycleFrames = Array(0..<bufferLength).cycled()
            frameIterator = cycleFrames.makeIterator()
        }
        
        
        
        public func synthesizeSignal(frequencyAmplitudePairs: [(f: Float32, a: Float32)],
                                     count: Int) -> [Float] {
            
            let tau: Float32 = Float32.pi * 2
            let signal: [Float32] = (0 ..< count).map { index in
                frequencyAmplitudePairs.reduce(0) { accumulator, frequenciesAmplitudePair in
                    let normalizedIndex = Float32(index) / Float(count)
                    return accumulator + sin(normalizedIndex * frequenciesAmplitudePair.f * tau) * frequenciesAmplitudePair.a
                }
            }
            
            return signal
        }
        
        var togglerInstance: Toggler = Toggler()
        var samplesIterator: (Array<Float32>.Iterator, Array<Float32>.Iterator) {
            print(togglerInstance.miscellaneousFunction())
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
            var channel_signals: [[Float32]] = [Array(repeating: Float32.zero, count: Int(bufferLength)), Array(repeating: Float32.zero, count: bufferLength)]
            let audio_buffer: [[Float32]] =  ({ (operation: (Int) -> (() -> [[Float32]])) in
                operation(bufferLength)()
            })( { frames in
                let frequencies: [Double] = [Double(dyads[0].harmonies[0].tones[0].frequencies[0]), Double(dyads[0].harmonies[0].tones[0].frequencies[1]),
                                             Double(dyads[0].harmonies[0].tones[1].frequencies[0]), Double(dyads[0].harmonies[0].tones[1].frequencies[1]),
                                             Double(dyads[0].harmonies[1].tones[0].frequencies[0]), Double(dyads[0].harmonies[1].tones[0].frequencies[1]),
                                             Double(dyads[0].harmonies[1].tones[1].frequencies[0]), Double(dyads[0].harmonies[1].tones[1].frequencies[1])]
                
                //                channel_signals = (Int.zero...44099).map { n -> Float32 in
                //                    let t: Double = scale(oldMin: Double.zero, oldMax: Double(bufferLength), value: Double(n), newMin: Double.zero, newMax: 1.0)
                //                    let f: Double = Double(0.125) * (sin(tau * frequencies[4] * t))
                //                    let f2: Double = Double(0.125) * (sin(tau * frequencies[4] * t))
                //                    return [Float32(f), Float32(f2)]
                //                } + (44100..<bufferLength).map { n -> Float32 in
                //                    let t: Double = scale(oldMin: Double.z.ero, oldMax: Double(bufferLength), value: Double(n), newMin: Double.zero, newMax: 1.0)
                //                    let f: Double = Double(0.125) * (sin(tau * frequencies[4] * t))
                //                    let f2: Double = Double(0.125) * (sin(tau * frequencies[4] * t))
                //
                //                    return [Float32(f), Float32(f2)]
                //                }
                
                let duration: Int = (dyads[0].harmonies[0].duration)
                for n in 0..<duration {
                    let t: Double = Double(n) / Double(duration)
                    let d: Double = Double(sin(t * tau))
                    
                    let p: Double = Double(sin(tau * t * frequencies[4]))
                    let r: Double = Double(sin(tau * t * (frequencies[4] * (5.0 / 4.0))))
                    let pr: Double = Double(((p + r) * d) + ((p + r) * abs(-d)))
                    
                    let u: Double = Double(sin(tau * t * (frequencies[4] + 220.0)))
                    let v: Double = Double(sin(tau * t * (frequencies[4] + 330.0)))
                    let uv: Double = Double(((u) * d) + ((u) * abs(-d)))
                    
                   
                    channel_signals[0][n] = Float32(d * pr)
                    channel_signals[1][n] = Float32(d * pr)
                }
                
                
                //                channel_signals[1] = (Int.zero...44099).map { n -> Float32 in
                //                    let t: Double = scale(oldMin: Double.zero, oldMax: Double(bufferLength), value: Double(n), newMin: Double.zero, newMax: 1.0)
                //                    let f: Double = Double(0.125) * (sin(tau * frequencies[4] * t))let f2: Double = Double(0.125) * (sin(tau * frequencies[4] * t))
                //                    return [Float32(f), Float32(f2)]
                //                } + (44100..<bufferLength).map { n -> Float32 in
                //                    let t: Double = scale(oldMin: Double.zero, oldMax: Double(bufferLength), value: Double(n), newMin: Double.zero, newMax: 1.0)
                //                    let f: Double = Double(0.125) * (sin(tau * frequencies[4] * t))let f2: Double = Double(0.125) * (sin(tau * frequencies[4] * t))
                //                    return [Float32(f), Float32(f2)]
                //                }
                
                
                
                //                let frequency: Float32 = (Float32(frequencies[4]) * (2.0 * Float32.pi))
                //
                //                var sineWave = [Float32](repeating: 0, count: Int(n))
                //
                //                // Calculate sin(2pi * time * frequency)
                //                vDSP_vsmul(c, stride, [frequency], &sineWave, stride, n)
                //                vvsinf(&sineWave, sineWave, [Int32(n)])
                
                //                var signal1 = synthesizeSignal(frequencyAmplitudePairs: [(f: Float32(frequencies[0]), a: (0.25 * Float32.pi))], count: bufferLength / 2)  //, [Float32](repeating: 0, count: bufferLength)]
                //                var signal = synthesizeSignal(frequencyAmplitudePairs: [(f: Float32(frequencies[1]), a: (0.25 * Float32.pi))], count: bufferLength / 2)
                
                return {
                    channel_signals
                    //                    [signal, signal1]
                }
            })
            
            return (audio_buffer[0].makeIterator(), audio_buffer[1].makeIterator())
        }
    }
}
