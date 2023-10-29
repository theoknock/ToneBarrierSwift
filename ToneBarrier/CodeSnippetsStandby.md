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
        let x = 0.0 + (((Float($0) - 0.0) * (1.0 - 0.0))) / (Double(~frameCount) - 0.0) // Float($0)
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
        debugPrint("observeValue")
        if keyPath == "isRunning",
           let running_state = change?[.newKey] {
            print("running_state is: \(running_state)")
        } else {
            print("keypath: \(String(describing: keyPath))")
            print("change.newKey: \(String(describing: change?[.newKey]))")
        }
    }
