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

