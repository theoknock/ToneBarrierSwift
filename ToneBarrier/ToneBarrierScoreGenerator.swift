////
////  ToneBarrierScoreGenerator.swift
////  ToneBarrier
////
////  Created by Xcode Developer on 12/2/23.
////

import Foundation
import AVFoundation
import Accelerate
import simd


// Calculating samples
// 1. Multiply a vector of normalized time and frequencies
// 2. Add the product to a vector of phase-increment accumulations
// 3. Multiply the sum by pi and then apply a sine function to the product

typealias CreateAudioBufferCompletionBlock = (AVAudioPCMBuffer) -> Void

let M_PI_SQR: simd_float4 = simd_make_float4(.pi) * simd_make_float4(Float32(2))

@objc class ToneBarrierScoreGenerator: NSObject {
    
    // To-Do:
    //       Use simd_mix to calculate transition values between channels (maybe)
    //       Use simd_smoothstep to interpolate values between -2pi to 2pi (phase/angle) based on the number of frames
    
    // This will print items in a random order, reshuffling after every 5 items (since there are 5 items in the collection)
    
    func createAudioBuffer(withFormat audioFormat: AVAudioFormat, completionBlock: CreateAudioBufferCompletionBlock) {
//        let tau: simd_float1 = simd_float1_
        let frameCount = AVAudioFrameCount(audioFormat.sampleRate)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        pcmBuffer.frameLength = frameCount
        
        // To-Do:
        //      Use a RandomNumberGenerator from the swift-algorithms package to randomly select a note from piano-scale note collection
        //      Get samples using the randomSample(count:using:) function
        //      Do the same for duration, using a collection of duration values at regular intervals (verses any number possible in the given range)
        
        let splitFrame = simd_float1(frameCount)/* * randomDoubleBetween(0.125, 0.875)*/
        let phaseAngularUnits = simd_double2x2(rows: [
            simd_double2(M_PI_SQR / splitFrame, M_PI_SQR / (simd_double1(frameCount) - splitFrame)),
            simd_double2(M_PI_SQR / (simd_double1(frameCount) - splitFrame), M_PI_SQR / splitFrame)
        ])
        
        // Assuming 'frequencies' and 'thetaIncrements' are defined earlier
        let thetaIncrements = phaseAngularUnits * frequencies
        let durations = simd_double2x2(rows: [
            simd_double2(splitFrame, simd_double1(frameCount) - splitFrame),
            simd_double2(simd_double1(frameCount) - splitFrame, splitFrame)
        ])
        
        var thetas = simd_double2x2()
        
        for frame in 0..<frameCount {
            let samples = simd_double2x2(rows: [
                _simd_sin_d2(simd_double2(thetas.columns.0)),
                _simd_sin_d2(simd_double2(thetas.columns.1))
            ])
            
            let a = simd_double2(samples.columns.0) * simd_double2(durations.columns.0)
            let b = simd_double2(samples.columns.1) * simd_double2(durations.columns.1)
            let abSum = _simd_sin_d2(a + b)
            let abSub = _simd_cos_d2(a - b)
            let abMul = abSum * abSub
            
            let finalSamples = simd_double2x2(rows: [
                simd_double2((2 * abMul) / 2) * simd_double2(durations.columns.1),
                simd_double2((2 * abMul) / 2) * simd_double2(durations.columns.0)
            ])
            
            thetas += thetaIncrements
            
            for channel in 0..<audioFormat.channelCount {
                pcmBuffer.floatChannelData?.pointee[Int(frame)] = Float(finalSamples.columns[Int(channel)][Int(frame)])
                if thetas.columns[Int(channel) ^ 1][Int(channel)] > M_PI_SQR {
                    thetas.columns[Int(channel) ^ 1][Int(channel)] -= M_PI_SQR
                }
                if thetas.columns[Int(channel)][Int(channel) ^ 1] > M_PI_SQR {
                    thetas.columns[Int(channel)][Int(channel) ^ 1] -= M_PI_SQR
                }
            }
        }
        
        completionBlock(pcmBuffer)
    }
    
    
    var audioFormat:     AVAudioFormat
    var audioFrameCount: AVAudioFrameCount
    var audioBufferList: UnsafeMutablePointer<AudioBufferList>
    var rng: RandomNumberGenerator
    
    override init() {
        rng = SimpleRNG(seed: Date().timeIntervalSince1970)
        let randomValue = rng.next()
        
        super.init()
    }
    
    convenience init(audioFormat: AVAudioFormat, audioFrameCount: AVAudioFrameCount, audioBufferList: inout UnsafeMutablePointer<AudioBufferList>) {
        self.init()
        
        self.audioFormat     = audioFormat
        self.audioFrameCount = audioFrameCount
        self.audioBufferList = audioBufferList
        // Additional initialization code if necessary
        
    }
    
    func pianoNoteFrequency() -> Float32 {
        let c: Float32 = Float32.random(in: (0.5...1.0))
        let f: Float32 = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
        
        return f
    }
    
    struct SimpleRNG: RandomNumberGenerator {
        private var seed: UInt32

        init(seed: UInt32) {
            self.seed = seed
        }

        mutating func next() -> UInt32 {
            let a: UInt32 = UInt32.min
            let c: UInt32 = UInt32.max
            seed = a &* seed &+ c
            return seed
        }
    }

    
    func createUniqueRandomGenerator<T>(from collection: [T]) -> () -> T? {
        var shuffledCollection = collection.shuffled()
        var currentIndex = 0
        
        return {
            // Check if all elements have been iterated over
            if currentIndex >= shuffledCollection.count {
                // Reshuffle the collection and reset the index
                shuffledCollection.shuffle()
                currentIndex = 0
            }
            
            // Return the current element and increment the index
            defer { currentIndex += 1 }
            return shuffledCollection[currentIndex]
        }
    }
    
    enum TonePairDyadDurationStops: CaseIterable {
        let toneDurationSplits: [simd_float1] = [simd_float1]([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75])

    static func random<G: RandomNumberGenerator>(using generator: inout G) -> toneDurationSplit {
        return Weekday.allCases.randomElement(using: &generator)!
    }


    static func random() -> Weekday {
        var g = SystemRandomNumberGenerator()
        return Weekday.random(using: &g)
    }
}
    
}
