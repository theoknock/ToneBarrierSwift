import Accelerate

class AudioSignalProcessor {

    let sampleRate: Double
    let length: Int

    init(sampleRate: Double, length: Int) {
        self.sampleRate = sampleRate
        self.length = length
    }

    func generateSignal(frequency: Double) -> [Double] {
        var time = [Double](repeating: 0.0, count: length)
        let increment = 1.0 / Double(length - 1)
        for i in 0..<length {
            time[i] = Double(i) * increment
        }
        
        // Validate time array values
        for value in time {
            assert(value >= 0.0 && value <= 1.0, "Value out of range: \(value)")
        }

        var signal = [Double](repeating: 0.0, count: length)
        var multiplier = 2 * Double.pi * frequency
        var intermediateTime = [Double](repeating: 0.0, count: length)

        // Use withUnsafeBufferPointer for safe memory access
        time.withUnsafeBufferPointer { timePointer in
            intermediateTime.withUnsafeMutableBufferPointer { intermediatePointer in
                vDSP_vsmulD(timePointer.baseAddress!, 1, &multiplier, intermediatePointer.baseAddress!, 1, vDSP_Length(length))
                vvsin(&signal, intermediatePointer.baseAddress!, [Int32(length)])
            }
        }

        return signal
    }

    func lowPassFilter(signal: [Double], filterCoefficients: [Double]) -> [Double] {
        var filteredSignal = [Double](repeating: 0.0, count: length)
        var delay = [Double](repeating: 0.0, count: 4)
        guard let setup = vDSP_biquad_CreateSetupD(filterCoefficients, 1) else {
            print("Error: Failed to create biquad setup.")
            return signal // Or handle the error as needed
        }

        vDSP_biquadD(setup, &delay, signal, 1, &filteredSignal, 1, vDSP_Length(length))
        vDSP_biquad_DestroySetupD(setup)

        return filteredSignal
    }
}

// Example usage
//let processor = AudioSignalProcessor(sampleRate: 44100.0, length: 88200)
//let frequency = 440.0
//let signal = processor.generateSignal(frequency: frequency)
//
//// Mixing two signals
//let signal1 = processor.generateSignal(frequency: 440.0)
//let signal2 = processor.generateSignal(frequency: 220.0)
//let mixedSignal = processor.mixSignals(signal1: signal1, signal2: signal2)
//
//// Low-pass filter example (replace with actual filter coefficients)
//let filterCoefficients: [Double] = [0.1, 0.15, 0.5, 0.15, 0.1]
//let filteredSignal = processor.lowPassFilter(signal: mixedSignal, filterCoefficients: filterCoefficients)

//
//// Example usage
//let processor = AudioSignalProcessor(sampleRate: 44100.0, length: 88200)
//let frequency = 440.0
//let signal = processor.generateSignal(frequency: frequency)
//
//// Mixing two signals
//let signal1 = processor.generateSignal(frequency: 440.0)
//let signal2 = processor.generateSignal(frequency: 220.0)
//let mixedSignal = processor.mixSignals(signal1: signal1, signal2: signal2)
//
//// Low-pass filter example (replace with actual filter coefficients)
//let filterCoefficients: [Double] = [0.1, 0.15, 0.5, 0.15, 0.1]
//let filteredSignal = processor.lowPassFilter(signal: mixedSignal, filterCoefficients: filterCoefficients)
