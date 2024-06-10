# Normalized time (array of pointers)    
    
    var frame: AVAudioFramePosition = 0
    var frame_t: UnsafeMutablePointer<AVAudioFramePosition> = UnsafeMutablePointer(&frame)
    var n_time: Float = .zero
    var n_time_t: UnsafeMutablePointer<Float> = UnsafeMutablePointer(&n_time)
    
    var normalized_times_ref: UnsafeMutablePointer<Float>? = nil;
    var normalized_times: (AVAudioFrameCount) -> UnsafeMutablePointer<Float>? = { (frame_count) in
        var normalized_time = [Float](repeating: .zero, count: Int(frame_count))
        normalized_times_ref = UnsafeMutablePointer(mutating: normalized_time)
        
        for frame in stride(from: frame_t.pointee, to: frame_count, by: 1) {
            n_time_t.pointee = 0.0 + (((frame - 0.0) * (1.0 - 0.0))) / (Float(~frame_count) - 0.0)
            normalized_times_ref?.advanced(by: Int(frame)).pointee = n_time_t.pointee
        }
        
        return normalized_times_ref
    }
    
    
    # Normalized time (Mapped [Float])
    
    normalized_times(AVAudioFrameCount(audio_format.sampleRate))
    
    let normalizedTime = (0 ..< Int(frameCount)).map {
        let x = 0.0 + (((Float($0) - 0.0) * (1.0 - 0.0))) / (Float64(~frameCount) - 0.0) // Float($0)
        return sin((Float(frequency) / Float(frameCount)) * x)
    }

# Channel mixer

            ((2.0 * M_PI) / frameCount) * frequency;
            ((2.0 * M_PI) / frameCount) * harmonic;
            let a = sin((Float(frequency) / Float(frameCount)) * x)
            let b = sin((Float(harmonic)  / Float(frameCount)) * x)
            return (2.0 * (sin(a + b) * cos(a - b))) / 2.0
            
# Using the sample rate and duration to compute signal samples

import Foundation

func generateSignalSamples(frequency: Float, sampleRate: Float, duration: Float) -> [Float] {
    let count = Int(sampleRate * duration)
    
    return (0..<count).map { i in
        return sinf(2 * Float.pi * frequency * Float(i) / sampleRate)
    }
}

# Misc audio sample generator functions

        let audio_format    = output_node.outputFormat(forBus: 0)
        let sample_rate     = Float(audio_format.sampleRate) * Float(audio_format.channelCount)
        
                func createSignalCosine(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
                let x = Float($0)
                return cos(Float(tau) * (x / Float(frameCount)) * frequency)
            }
            return inputSignal
        }
        
        var normalized_times: (AVAudioFrameCount) -> UnsafeMutablePointer<Float>? = { (frame_count) in
            var normalized_time = [Float](repeating: .zero, count: Int(frame_count))
            normalized_times_ref = UnsafeMutablePointer(mutating: normalized_time)
            
            for frame in stride(from: frame_t.pointee, to: frame_count, by: 1) {
                n_time_t.pointee = 0.0 + (((frame - 0.0) * (1.0 - 0.0))) / (Float(~frame_count) - 0.0)
                normalized_times_ref?.advanced(by: Int(frame)).pointee = n_time_t.pointee
            }
            
            return normalized_times_ref
        }
        
        func createSignalSine(frameCount: Int, frequency: Float) -> [Float] {
            let inputSignal = (0 ..< frameCount).map {
                return sin(Float(tau) * (x / Float(frameCount)) * frequency)
            }
            return inputSignal
        }
        
        
        func multiplySignals(frameCount: Int, array1: [Float], array2: [Float]) -> [Float] {
            var result = [Float](repeating: .zero, count: frameCount)
            vDSP.multiply(array1, array2, result: &result)
            return result
        }

# Observing KVO changes

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        debug//print("observeValue")
        if keyPath == "isRunning",
           let running_state = change?[.newKey] {
            //print("running_state is: \(running_state)")
        } else {
            //print("keypath: \(String(describing: keyPath))")
            //print("change.newKey: \(String(describing: change?[.newKey]))")
        }
    }

# Crappy, non-working randomizes and distributors

        let distribution = GKGaussianDistribution(lowestValue: 1, highestValue: 8)
                func redistributeValueUsingGaussianCurve(value: Float32, mean: Float32, standardDeviation: Float32) -> Float32 {
                    // Calculate the z-score of the value.
                    let zScore = (value - mean) / standardDeviation
        
                    // Calculate the probability of the value under the Gaussian curve.
                    let probability = 1 / sqrt(2 * Float32.pi * standardDeviation * standardDeviation) * exp(-zScore * zScore / 2)
        
                    // Return the redistributed value.
                    return probability * standardDeviation + mean
                }
        
        
        let gaussianDistribution: (Float32, Float32, Float32) -> Float32 = { t, m, v in
            let standardDeviation = Float32(sqrt(v))
            let normalizationFactor = 1 / (standardDeviation * sqrt(2 * Float32.pi))
            let exponentNumerator = -pow(t - m, 2)
            let exponentDenominator = 2 * v
            let exponent = exponentNumerator / exponentDenominator
            let gaussianValue = normalizationFactor * Float32(exp(exponent))
            
            return gaussianValue
        }
        
        let gaussianDistribution_: (Float32, Float32, Float32) -> Float32 = { x, mean, variance in
            let numerator = pow(x - mean, 2)
            let denominator = 2 * pow(variance, 2)
            let exponent = -numerator / denominator
            let gaussianValue = exp(exponent)
            
            return gaussianValue
        }
        
        
        func scale(min_new: Float32, max_new: Float32, val_old: Float32, min_old: Float32, max_old: Float32) -> Float32 {
            let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
            return val_new;
        }
        
        var generateNormalizedRandom: () -> (() -> Float) = {
            srand48(Int(time(nil)))
            var random: Float = 0.0
            return {
                return {
                    random = Float(drand48())
                    return random
                }
            }()
        }
        
        
                static Float32 (^(^generate_normalized_random)(void))(void) = ^{
                    srand48((unsigned int)time(0));
                    static Float32 random;
                    return ^ (Float32 * random_t) {
                        return ^ Float32 {
                            return (*random_t = (drand48()));
                        };
                    }(&random);
                };
        
                typedef typeof(Float32(^)(void)) random_generator;
                typedef typeof(Float32(^(* restrict))(void)) random_n_t;
                static Float32 (^(^(^(^generate_random)(Float32(^)(void)))(Float32(^)(Float32)))(Float32(^)(Float32)))(void) = ^ (Float32(^randomize)(void)) {
                    return ^ (Float32(^distribute)(Float32)) {
                        return ^ (Float32(^scale)(Float32)) {
                                return ^ Float32 {
                                    return scale(distribute(randomize()));
                                };
                        };
                    };
                };
        
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
        
        
        
        
        func RandomNumberGenerator() -> () -> Float32 {
            var descriptor = BNNSNDArrayDescriptor.allocateUninitialized(
                scalarType: Float32.self,
                shape: .vector(1, stride: Int.Stride()))
            
            let randomNumberGenerator = BNNSCreateRandomGenerator(
                BNNSRandomGeneratorMethodAES_CTR,
                nil)
            
            func generateRandomNumber() -> Float32 {
                
                BNNSRandomFillNormalFloat(randomNumberGenerator,
                                          &descriptor,
                                          0.5,
                                          1.0)
                
                let bytesPointer = UnsafeMutableRawPointer.allocate(byteCount: Int(Float32.Stride()), alignment: 1)
                bytesPointer.storeBytes(of: (descriptor.data?.load(fromByteOffset: 0, as: Float32.self))! , as: Float32.self)
                let x = bytesPointer.load(as: Float32.self)
                //print("\(x)\n")
                
                return x
            }
            return generateRandomNumber
        }
        
        let random_number = RandomNumberGenerator()
        
        
        
        func randomFloats(n: Int,
                          mean: Float32,
                          standardDeviation: Float32) -> [Float32] {
            
            let result = [Float](unsafeUninitializedCapacity: n) {
                
                buffer, unsafeUninitializedCapacity in
                
                guard
                    var arrayDescriptor = BNNSNDArrayDescriptor(
                        data: buffer,
                        shape: .vector(n)),
                    let randomNumberGenerator = BNNSCreateRandomGenerator(
                        BNNSRandomGeneratorMethodAES_CTR,
                        nil) else {
                    fatalError()
                }
                
                BNNSRandomFillNormalFloat(
                    randomNumberGenerator,
                    &arrayDescriptor,
                    mean,
                    standardDeviation)
                
                unsafeUninitializedCapacity = n
                BNNSDestroyRandomGenerator(randomNumberGenerator)
            }
            return result
        }


# Signal-generator code

        return (Int.zero ..< frame_count).map { i in
            if i == 0 {
                signalFrequency = [randomPianoNoteFrequency(), randomPianoNoteFrequency()]
                signalIncrement = [signalFrequency[0] * phaseIncrement[0], signalFrequency[1] * phaseIncrement[1]]
            }
            
            return (Int.zero ..< 2).map { j in
                //                    signalPhase = [sin(signalPhase[0]), sin(signalPhase[1])]
                //                    frequency_samples = [[signalPhase[0]], [signalPhase[1]]] //sin(signalPhase[0])[0], sin(signalPhase[1])[1]]
                //                    signalPhase       = [(signalPhase[0] + signalIncrement[0]), (signalPhase[0] + signalIncrement[0])]
                //
                //                    defer {
                //                        //                    if currentPhase >= tau { currentPhase -= tau }
                //                        //                    if currentPhase < Float32.zero { currentPhase += tau }
                //                    }
                
                return Float32.zero
            }
            return [Float32]
        }
    }
    
    func generateFrequency(frame_count: Int) -> [Float32] {
        //            var frequency_samples = Array(repeating: Array(repeating: Float32.zero, count: 2), count: 2)
        var frequency_samples: [([Float32])] = [[Float32](repeating: Float32.zero, count: frame_count), [Float32](repeating: Float32.zero, count: frame_count)]
        let frame_indicies = incrementer(frame_count)
        let signal_samples: [([Float32])] = (Int.zero ..< frame_count).map { i in
            // get value at i in frame_indicies and set phaseIncrement to a new value if frame_indicies[i] == 0
            if i == 0 {
                signalFrequency = [randomPianoNoteFrequency(), randomPianoNoteFrequency()]
                signalIncrement = [signalFrequency[0] * phaseIncrement[0], signalFrequency[1] * phaseIncrement[1]]
            }
            
            signalPhase = [sin(signalPhase[0]), sin(signalPhase[1])]
            frequency_samples = [[signalPhase[0]], [signalPhase[1]]] //sin(signalPhase[0])[0], sin(signalPhase[1])[1]]
            signalPhase       = [(signalPhase[0] + signalIncrement[0]), (signalPhase[0] + signalIncrement[0])]
            
            defer {
                //                    if currentPhase >= tau { currentPhase -= tau }
                //                    if currentPhase < Float32.zero { currentPhase += tau }
            }
            
            return frequency_samples
        }
        
        return signal_samples
    }
    

# Sample-buffer generator template


        func sample_buffers(frame_count: Int) -> [([Float32])] {
            var buffers: [([Float32])] = [[Float32](repeating: Float32.zero, count: frame_count), [Float32](repeating: Float32.zero, count: frame_count)]
            return buffers.map { innerArray in
                (Int.zero ..< frame_count).map {
                    return Float32($0)
                }
            }
        }
