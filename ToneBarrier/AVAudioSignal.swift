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

var frequency = 440.0
let amplitude = 1.0
let duration  = 5.0
let twoPi     = 2.0 * Float.pi

let sine = { (phase: Float) -> Float in
    return sin(phase)
}

let tremolo = { (frequency: Float, time: Float) -> Float in
    let interval_max: Float = (frequency - 440.0) / (880.0 - 440.0) * 8.0
//    let interval_min: Float =
    let dampened: Float = ((((time * interval_max)-4)/(interval_max - 4)) * interval_max)
    return dampened
}

@objc class AVAudioSignal: NSObject {
    private static let shared = AVAudioSignal()
    
    let audio_engine: AVAudioEngine = AVAudioEngine()
    let audio_source_node: AVAudioSourceNode
    let audio_source_node_renderer: AVAudioSourceNodeRenderBlock
    
    override init() {
        
        let signal: (Float) -> Float = sine
        let main_mixer_node = audio_engine.mainMixerNode
        let output_node = audio_engine.outputNode
        let audio_format = output_node.outputFormat(forBus: 0)
        let frame_count = Int(Float(audio_format.sampleRate) * Float(audio_format.channelCount))
        let angular_velocity = { () -> Float in
            return (Float(twoPi) / Float(frame_count))
        }
        let normalized_time = { (index: Float, count: Float) -> Float in
            return index / count
        }
        var currentPhase: Float = 0
        var phaseIncrement = angular_velocity() * Float(frequency)
        
        var currentTremoloPhase: Float = 0
        var phaseTremoloIncrement = angular_velocity() * Float(tremolo(Float(frequency), 0.0))
        
        var frame_position: Int = 0;
        var bit: Int = 1
        
        self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                frame_position += (frame_position == frame_count) ? {
                    frequency = frequency + 100
                    phaseIncrement = angular_velocity() * Float(frequency)
                    phaseTremoloIncrement = angular_velocity() * Float(tremolo(Float(frequency), 0.0))
//                    bit ^= 1 // Alternates between channels
                    return -frame_count }() : 1
                phaseTremoloIncrement = angular_velocity() * Float(tremolo(Float(frequency), normalized_time(Float(frame_position), Float(frame_count))))
                let value = (signal(Float(currentPhase)) * signal(Float(currentTremoloPhase)))
                currentPhase += phaseIncrement
                if currentPhase >= twoPi {
                    currentPhase -= twoPi
                }
                if currentPhase < 0.0 {
                    currentPhase += twoPi
                }
                currentTremoloPhase += phaseTremoloIncrement
                if currentTremoloPhase >= twoPi {
                    currentTremoloPhase -= twoPi
                }
                if currentTremoloPhase < 0.0 {
                    currentTremoloPhase += twoPi
                }
                
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = (value * Float(bit))
//                    debugPrint("index: \(buf.indices)")
//                    bit ^= 1 // Isolates to one channel (or just add 1 to frame)
                }
            }
            return noErr
        }
        
        //    self.audio_source_node_renderer = { _, _, frameCount, audioBufferList in
        //        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        //        for frame in 0..<Int(frameCount) {
        //            let value = signal(Float(currentPhase)) * Float(amplitude)
        //            currentPhase += phaseIncrement
        //            if currentPhase >= twoPi {
        //                currentPhase -= twoPi
        //            }
        //            if currentPhase < 0.0 {
        //                currentPhase += twoPi
        //            }
        //            for buffer in ablPointer {
        //                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
        //                buf[frame] = value
        //            }
        //        }
        //        return noErr
        //    }
        
        self.audio_source_node = AVAudioSourceNode(format: audio_format, renderBlock: audio_source_node_renderer)
        
        audio_engine.attach(self.audio_source_node)
        audio_engine.connect(self.audio_source_node, to: main_mixer_node, format: audio_format)
        audio_engine.connect(main_mixer_node, to: output_node, format: audio_format)
    }
    
}

//extension AVAudioSignal {
//    typeof(simd_double1(^)(simd_double1)) rescale_random_frequency;
//    typeof(simd_double1(^(* restrict))(simd_double1)) _Nullable rescale_random_frequency_t = &rescale_random_frequency;
//    typeof(simd_double1(^)(simd_double1)) rescale_random_duration;
//    typeof(simd_double1(^(* restrict))(simd_double1)) _Nullable rescale_random_duration_t  = &rescale_random_duration;
//    static inline typeof(simd_double1(^)(simd_double1)) random_rescaler (simd_double1 old_min, simd_double1 old_max, simd_double1 new_min, simd_double1 new_max) {
//        return ^ simd_double1 (simd_double1 value) {
//            return (simd_double1)(value = (new_max - new_min) * (value - old_min) / (old_max - old_min) + new_min);
//        };
//    }
//    typeof(random_rescaler) * random_rescaler_t = &random_rescaler;
//
//    typeof(simd_double1(^)(simd_double1)) distribute_random_frequency;
//    typeof(simd_double1(^(* restrict))(simd_double1)) _Nullable distribute_random_frequency_t = &distribute_random_frequency;
//    typeof(simd_double1(^)(simd_double1)) distribute_random_duration;
//    typeof(simd_double1(^(* restrict))(simd_double1)) _Nullable distribute_random_duration_t  = &distribute_random_duration;
//    typeof(simd_double1 (^(^)(simd_double1))(simd_double1)) gaussian_distributor = ^ (simd_double1 mean) {
//        return ^ simd_double1 (simd_double1 time) {
//            return (time = (simd_double1)(exp(-(pow(((time * M_PI) - mean), 2.0)))));
//        };
//    };
//    typeof(gaussian_distributor) * gaussian_distributor_t = &gaussian_distributor;
//
//    static inline typeof(simd_double1(^)(simd_double1)) triangle_wave_distributor (const simd_double1 periods) {
//        return ^ simd_double1 (simd_double1 time) {
//            return (time = (2.f * (1.f / M_PI)) * (asin(sin(M_PI * time))));
//        };
//    }
//    typeof(triangle_wave_distributor) * triangle_wave_distributor_t = &triangle_wave_distributor;
//
//    typeof(simd_double1 (^(^)(void))(simd_double1)) gabor_function = ^{
//        return ^ simd_double1 (simd_double1 time) {
//            return (time = exp((-2.f * M_PI) * (pow(M_PI * (time + 0.5f), 2.f))));;
//        };
//    };
//    typeof(gabor_function) * gabor_function_t = &gabor_function;
//
//    typeof(simd_double1(^)(void)) generate_randomd48;
//    typeof(simd_double1(^(* restrict))(void)) _Nullable generate_randomd48_t = &generate_randomd48;
//    static inline typeof(simd_double1(^)(void)) randomizerd48_generator (void) {
//        srand48((unsigned long)time(0));
//        static simd_double1 random;
//        return ^ (simd_double1 * random_t) {
//            return ^ simd_double1 {
//                return (simd_double1)(*random_t = (drand48()));
//            };
//        }(&random);
//    }
//
//    typedef typeof(simd_double1(^)(void)) random_generator;
//    static simd_double1 (^(^(^(^randomizer_generator)(simd_double1(^)(void)))(simd_double1(^)(simd_double1)))(simd_double1(^)(simd_double1)))(void) = ^ (simd_double1(^randomize)(void)) {
//        return ^ (simd_double1(^distribute)(simd_double1)) {
//            return ^ (simd_double1(^rescale)(simd_double1)) {
//                static simd_double1 result;
//                return ^ (simd_double1 * result_t) {
//                    return ^ simd_double1 {
//                        return (simd_double1)(*result_t = rescale(distribute(randomize())));
//                    };
//                }(&result);
//            };
//        };
//    };
//
//    static simd_double2 (^frequency_harmonizer)(typeof(random_generator)) = ^ (typeof(random_generator) randomizer) {
//        static simd_double1 result;
//        return ^ (simd_double1 * result_t) {
//            return simd_make_double2((*result_t = randomizer()), (*result_t *= (5.f / 4.f)));
//        }(&result);
//    };
//}



//typedef NS_ENUM(NSUInteger, Trill) {
//    TonalTrillUnsigned,
//    TonalTrillInverse
//};

//+ (double(^)(double, double))Frequency
//{
//    return ^double(double time, double frequency)
//    {
//        return pow(sinf(M_PI * time * frequency), 2.0);
//    };
//}

//+ (double(^)(double))TrillInterval
//{
//    return ^double(double frequency)
//    {
//        return ((frequency / (max_frequency - min_frequency) * (max_trill_interval - min_trill_interval)) + min_trill_interval);
//    };
//}

//+ (double(^)(double, double))Trill
//{
//    return ^double(double time, double trill)
//    {
//        return pow(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5, 4.0);
//    };
//}

//+ (double(^)(double, double))TrillInverse
//{
//    return ^double(double time, double trill)
//    {
//        return pow(-(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5) + 1.0, 4.0);
//    };
//}

//typedef double (^Normalize)(double, double, double);
//Normalize normalize = ^double(double min, double max, double value)
//{
//    double result = (value - min) / (max - min);
//    
//    return result;
//};
//
//typedef double (^FrequencySample)(double, double, double);
//FrequencySample sample_frequency = ^(double time, double frequency, double trill)
//{
//    double result = sinf(M_PI * time * frequency) * ^double
//                                        (double time, double trill) {
//        return (sinf(M_PI_PI * time * trill) / 2); //((frequency / (2000.0 - 400.0) * (12.0 - 4.0)) + 4.0);
//    } (time, trill);
//    
//    return result;
//};
//
//typedef double (^AmplitudeSample)(double, double, double);
//AmplitudeSample sample_amplitude = ^(double time, double gain, double tremolo)
//{
//    double result =  sinf((M_PI_PI * time * tremolo) / 2) * (time * gain);
//    
//    return result;
//};


//@objc class AudioEngine: AVAudioEngine {
//    override func start() throws {
//        do {
//            try super.start()
//        } catch {
//            debugPrint("Could not start audio engine: \(error)")
//        }
//    }
//
//    override init() {
//        super.init()
//    }
//
//
//}

//extension AVAudioEngine {
//    struct StaticVars {
//        lazy var token = {0}()
//    }
//
//    public override class func init() {
////        var outCount: UnsafeMutablePointer<UInt32>?
//        var methodList: UnsafeMutablePointer<Method>? = class_copyMethodList(object_getClass(audio_engine), outCount)
//        for i in 0..<(outCount?.pointee ?? 0) {
//            var currentMethod: Method = methodList![Int(i)]
//            var methodSelector: Selector = method_getName(currentMethod)
//            debugPrint("\(currentMethod) \(methodSelector)")
//        }
//
//    }
//
//    public override class func initialize() {
//        dispatch_once(&StaticVars.token) {
//            guard self == UIScrollView.self else {
//                return
//            }
//            // Accessor
//            method_exchangeImplementations(
//                class_getInstanceMethod(self, Selector("swizzledContentOffset")),
//                class_getInstanceMethod(self, Selector("contentOffset"))
//            )
//            // Two-param setter
//            method_exchangeImplementations(
//                class_getInstanceMethod(self, #selector(UIScrollView.setContentOffset(_:animated:))),
//                class_getInstanceMethod(self, #selector(UIScrollView.swizzledSetContentOffset(_:animated:)))
//            )               
//            // One-param setter
//            method_exchangeImplementations(
//                class_getInstanceMethod(self, #selector(UIScrollView.swizzledSetContentOffset(_:))),
//                class_getInstanceMethod(self, Selector("setContentOffset:")))
//        }
//    }
//
//    func swizzledSetContentOffset(inContentOffset: CGPoint, animated: Bool) {
//        print("Some interceding code for the swizzled 2-param setter with \(inContentOffset)")
//        // This is not recursive. The method implementations have been exchanged by runtime. This is the
//        // original setter that will run.
//        swizzledSetContentOffset(inContentOffset, animated: animated)
//    }
//
//
//    func swizzledSetContentOffset(inContentOffset: CGPoint) {
//        print("Some interceding code for the swizzled 1-param setter with \(inContentOffset)")
//        swizzledSetContentOffset(inContentOffset) // not recursive
//    }
//
//
//    var swizzledContentOffset: CGPoint {
//        get {
//            print("Some interceding code for the swizzled accessor: \(swizzledContentOffset)") // false warning
//            return swizzledContentOffset // not recursive, false warning
//        }
//    }
//}

