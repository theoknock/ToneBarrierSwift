//
//  TBAudioSignal.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 10/28/23.
//

import Foundation
import AVFoundation


let frequency = Float(440.0)
let amplitude = Float(1.0)
let duration = Float(5.0)

let twoPi = 2 * Float.pi

let sine = { (phase: Float) -> Float in
    return sin(phase)
}

let engine = AVAudioEngine()
let mainMixer = engine.mainMixerNode
let output = engine.outputNode
let outputFormat = output.inputFormat(forBus: 0)
let sampleRate = Float(outputFormat.sampleRate)
// Use the output format for the input, but reduce the channel count to 1.
let inputFormat = AVAudioFormat(commonFormat: outputFormat.commonFormat,
                                sampleRate: outputFormat.sampleRate,
                                channels: 1,
                                interleaved: outputFormat.isInterleaved)

var currentPhase: Float = 0
// The interval to advance the phase each frame.
let phaseIncrement = (twoPi / sampleRate) * frequency

let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
    let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
    for frame in 0..<Int(frameCount) {
        // Get the signal value for this frame at time.
        let value = sine(currentPhase) * amplitude
        // Advance the phase for the next frame.
        currentPhase += phaseIncrement
        if currentPhase >= twoPi {
            currentPhase -= twoPi
        }
        if currentPhase < 0.0 {
            currentPhase += twoPi
        }
        // Set the same value on all channels (due to the inputFormat, there's only one channel though).
        for buffer in ablPointer {
            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
            buf[frame] = value
        }
    }
    return noErr
}
