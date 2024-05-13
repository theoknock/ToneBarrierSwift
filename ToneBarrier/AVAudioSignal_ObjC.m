//
//  AVAudioSignal_ObjC.m
//  ToneBarrier
//
//  Created by Xcode Developer on 1/27/24.
//

#import "AVAudioSignal_ObjC.h"
@import Accelerate;

@implementation AVAudioSignal_ObjC

- (AVAudioSourceNodeRenderBlock)audioSourceNodeRenderBlockMethod {
    NSLog(@"%s\n", __PRETTY_FUNCTION__);
    __block Float32 theta = 0.f;
    const Float32 frequency = 880.f;
    const Float32 sampleRate = 48000.f;
    const Float32 amplitude = 0.25f;
    const Float32 M_PI_SQR = 2.f * M_PI;
    
    return ^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp, AVAudioFrameCount frameCount, AudioBufferList * _Nonnull outputData) {
        Float32 theta_increment = M_PI_SQR * frequency / sampleRate;
        Float32 * buffer = (Float32 *)outputData->mBuffers[0].mData;
        for (AVAudioFrameCount frame = 0; frame < frameCount; frame++) {
            buffer[frame] = sin(theta) * amplitude;
            theta += theta_increment;
            if (theta > M_PI_SQR) {
                theta -= M_PI_SQR;
            }
        }
        return (OSStatus)noErr;
    };
}

- (AVAudioSourceNode *)createAudioSourceNodeWithFormat:(AVAudioFormat *)audioFormat {
    NSLog(@"%s\n", __PRETTY_FUNCTION__);
    AVAudioFormat * _input_audio_format  = [[AVAudioFormat alloc] initWithCommonFormat:audioFormat.commonFormat
                                                                            sampleRate:audioFormat.sampleRate
                                                                              channels:audioFormat.channelCount
                                                                           interleaved:audioFormat.interleaved];
    // audio source node
    __block Float32 phase_increment = 1.f / _input_audio_format.sampleRate;
    NSLog(@"phase_increment == %f\n", phase_increment);
    AVAudioSourceNode *sourceNode = [[AVAudioSourceNode alloc] initWithFormat:_input_audio_format renderBlock:^OSStatus(BOOL * _Nonnull isSilence, const AudioTimeStamp * _Nonnull timestamp, AVAudioFrameCount frameCount, AudioBufferList * _Nonnull outputData) {
        
//        // signal sample array(s) stride and length
        vDSP_Stride stride = (vDSP_Stride)1;
        vDSP_Length length = (vDSP_Length)frameCount;
//        
//        // phase increment array
        Float32 accumulative_phase = -phase_increment, phase_steps[length];
        Float32 * phase_steps_t    = &phase_steps[0];
        vDSP_vfill(^ Float32 * (Float32 phase_step) {
            Float32 * phase_step_t = &phase_step;
            return phase_step_t;
        }(({ accumulative_phase += phase_increment; })), phase_steps_t, stride, length);
        NSLog(@"accumulative_phase == %f\n", accumulative_phase);
        
//
//        // amplitude array
        Float32   angular_unit    = sinf(2 * M_PI), angular_units[length];
        Float32 * angular_unit_t  = &angular_unit;
        Float32 * angular_units_t = &angular_units[0];
        vDSP_vfill(angular_unit_t, angular_units_t, stride, length);
//        
//        // frame indicies/frame_count/time arrays [0 through frameCount, frameCount[frameCount and 0 through 1]
        Float32   frame_counter   = -1, frame_count[length], frame_indices[length], time[length];
        Float32 * frame_count_t   = &frame_count[0];
        Float32 * frame_indices_t = &frame_indices[0];
        Float32 * time_t          = &time[0];
        vDSP_vfill(^ Float32 * (Float32 frame_index) {
            Float32 * frame_index_t = &frame_index;
            return frame_index_t;
        }(({ frame_counter = frame_counter + 1; })), frame_indices_t, stride, length);
        
        // ERROR
//        vDSP_vfill(frame_count_t, (Float32 *)(&frameCount), stride, length);
        // ERROR
        
        vDSP_vdiv(frame_count_t, stride, frame_indices_t, stride, time, stride, length);
//        
//        // Calculate amplitude
        Float32 amplitude_signal_sample[length];
        Float32 * amplitude_signal_sample_t = &amplitude_signal_sample[0];
        vDSP_vmul(angular_units_t, stride, time_t, stride, amplitude_signal_sample_t, stride, length);
        
        Float32 * output_data_t = (Float32 *)outputData->mBuffers[0].mData;
        vDSP_vmul(frame_indices_t, stride, angular_units_t, stride, output_data_t, stride, length);
        printf("time_t == %f\n", *time_t);
//
        return (OSStatus)noErr;
    }];
    
    return sourceNode;
}

@end
