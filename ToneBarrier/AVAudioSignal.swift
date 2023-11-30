//
//  AudioSignal.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 4/29/23.
//

import Foundation
import AVFoundation
import AVKit
import SwiftUI
import Combine
import ObjectiveC
import Dispatch
import Accelerate
import GameKit

var octave:       Float32 = Float32(440.0 * 2.0)
var root:         Float32 = Float32(octave * 0.5)
var harmonic:     Float32 = Float32(root * (3.0/2.0))

var root_:        Float32 = Float32(root  *  2.0)
var harmonic_:    Float32 = Float32(root_ * (3.0/2.0))
var amplitude:    Float32 = Float32(0.25)
var envelope:     Float32 = Float32(1.0)
let tau:          Float32 = Float32(Float32.pi * 2.0)
let theta:        Float32 = Float32(Float32.pi / 2.0)
let trill:        Float32 = Float32.zero
let tremolo:      Float32 = Float32(1.0)
var split:        Int32   = Int32(2)
var duration:     Int32   = Int32.zero

func scale(min_new: Float32, max_new: Float32, val_old: Float32, min_old: Float32, max_old: Float32) -> Float32 {
    let val_new = min_new + (((val_old - min_old) * (max_new - (min_new))) / (max_old - min_old))
    return val_new;
}

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    
    override init() {
        let main_mixer_node: AVAudioMixerNode = audio_engine.mainMixerNode
        let audio_format: AVAudioFormat       = AVAudioFormat(standardFormatWithSampleRate: audio_engine.mainMixerNode.outputFormat(forBus: Int.zero).sampleRate, channels: audio_engine.mainMixerNode.outputFormat(forBus: Int.zero).channelCount )!
        let buffer_length: Int32              = Int32(audio_format.sampleRate) * Int32(audio_format.channelCount)
        
        func pianoNoteFrequency() -> Float32 {
            let c: Float32 = Float32.random(in: (0.5...1.0))
            let f: Float32 = 440.0 * pow(2.0, (floor(c * 88.0) - 49.0) / 12.0)
            
            return f
        }
        
        struct CircularArray<T> {
            private var array: [T]
            private var currentIndex: Int = 0

            init(_ elements: [T]) {
                self.array = elements
            }

            mutating func next() -> T {
                let element = array[currentIndex]
                currentIndex = (currentIndex + 1) % (array.count)
                return element
            }
        }

        // To-Do: Pass two joined Arrays of varied duration/length to circularArray parameter
        var duration = (buffer_length / 2)
        var circularNumbers = CircularArray(Array(0..<buffer_length))// CircularArray(Array(0..<duration) + Array(0..<duration))
        var n: Int32 = Int32.zero
        
        let e_sustain: (Float32, Float32) -> Float32 = { t,d in
            return pow(sin(Float32.pi * t), d) // 2.0 to 10.0
        }
        let e_attack: (Float32, Float32) -> Float32 = { t, d in
            return pow(sin(pow(Float32.pi * t, 0.5)), d) // 2.0 to 10.0
        }
        let e_release: (Float32, Float32) -> Float32 = { t, d in
            return pow(sin(pow(Float32.pi * t, 2.0)), d) // 2.0 to 10.0
        }
        
        let envelopes = [e_attack, e_sustain]
        var fadeBit: UInt32 = 1
        
        
        func store_note_frequency() -> (Float32) -> ([Float32]) {
            var storedOctave:   Float32 = Float32.zero
            var storedRoot:     Float32 = Float32.zero
            var storedHarmonic: Float32 = Float32.zero
            var storedSum: Float32 = Float32.zero

            return { newValue in
                storedRoot     = newValue * 0.5
                storedOctave   = newValue
                storedHarmonic = newValue * (2.0 / 3.0)
                storedSum = storedRoot + storedHarmonic
                return [storedRoot, storedHarmonic, storedOctave]
            }
        }
        let note_frequencies  = store_note_frequency()
        var combination_notes = note_frequencies(pianoNoteFrequency())
        
        func generateFrequencies(frame_count: Int) -> [[Float32]] {
            var left_channel_samples:  [Float32] = [Float32](repeating: Float32.zero, count: frame_count)
            var right_channel_samples: [Float32] = [Float32](repeating: Float32.zero, count: frame_count)
            var combined_frequency_samples: [[Float32]] = [[Float32]]([left_channel_samples, right_channel_samples])
            for i in 0..<frame_count {
                n = circularNumbers.next()
                if n == 0 {
                    combination_notes = note_frequencies(pianoNoteFrequency())
                    fadeBit ^= 1
                }
                let t  = Float(n) / (Float(buffer_length) - 1.0)
                // To-Do: Generate two circular counter arrays, one for each envelope/frequency to crossfade tones
                left_channel_samples[i]  = e_sustain(t, 1.0) * (sin(tau * combination_notes[Int(0)] * t) + sin(tau * combination_notes[Int(1)] * t))
                right_channel_samples[i] = e_sustain(t, 1.0) * (sin(tau * combination_notes[Int(1)] * t) + sin(tau * combination_notes[Int(2)] * t))
                combined_frequency_samples[0][i] = left_channel_samples[i]
                combined_frequency_samples[1][i] = right_channel_samples[i]
            }
            
            return combined_frequency_samples
        }
        
        let audio_source_node: AVAudioSourceNode = AVAudioSourceNode(format: audio_format, renderBlock: { _, _, frameCount, audioBufferList in
            let signalSamples    = generateFrequencies(frame_count: Int(frameCount))
            let ablPointer       = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let leftChannelData  = ablPointer[0]
            let rightChannelData = ablPointer[1]
            let leftBuffer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(leftChannelData)
            let rightBuffer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(rightChannelData)
            signalSamples.withUnsafeBufferPointer { sourceBuffer in
                ([Float32]([Float32](sourceBuffer[0]))).withUnsafeBufferPointer { leftSourceBuffer in
                    leftBuffer.baseAddress!.initialize(from: leftSourceBuffer.baseAddress!, count: Int(frameCount))
                }
                ([Float32]([Float32](sourceBuffer[1]))).withUnsafeBufferPointer { rightSourceBuffer in
                    rightBuffer.baseAddress!.initialize(from: rightSourceBuffer.baseAddress!, count: Int(frameCount))
                }
            }
            return noErr
        })
        
        audio_engine.attach(audio_source_node)
        audio_engine.connect(audio_source_node, to: main_mixer_node, format: audio_format)
    }
}

