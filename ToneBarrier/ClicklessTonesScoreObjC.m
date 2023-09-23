//
//  ClicklessTonesScoreObjC.m
//  ToneBarrier
//
//  Created by Xcode Developer on 9/23/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <GameKit/GameKit.h>

#import "ClicklessTonesScoreObjC.h"

@interface ClicklessTonesScoreObjC ()
{
    double duration_bifurcate;
}

@property (nonatomic, readonly) GKMersenneTwisterRandomSource * _Nullable randomizer;
@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor;

// Randomizes duration
@property (nonatomic, readonly) GKGaussianDistribution * _Nullable distributor_duration;


@end

typedef void (^PlayToneCompletionBlock)(void);
typedef void (^CreateAudioBufferCompletionBlock)(AVAudioPCMBuffer * _Nonnull buffer1, AVAudioPCMBuffer * _Nonnull buffer2, PlayToneCompletionBlock _Nonnull playToneCompletionBlock);

@implementation ClicklessTonesScoreObjC

typedef NS_ENUM(NSUInteger, TonalHarmony) {
    TonalHarmonyConsonance,
    TonalHarmonyDissonance,
    TonalHarmonyRandom
};

typedef NS_ENUM(NSUInteger, TonalInterval) {
    TonalIntervalUnison,
    TonalIntervalOctave,
    TonalIntervalMajorSixth,
    TonalIntervalPerfectFifth,
    TonalIntervalPerfectFourth,
    TonalIntervalMajorThird,
    TonalIntervalMinorThird,
    TonalIntervalRandom
};

typedef NS_ENUM(NSUInteger, TonalEnvelope) {
    TonalEnvelopeAverageSustain,
    TonalEnvelopeLongSustain,
    TonalEnvelopeShortSustain
};

static __inline__ double Tonality(double frequency, TonalInterval interval, TonalHarmony harmony)
{
    double new_frequency = frequency;
    switch (harmony) {
        case TonalHarmonyDissonance:
            new_frequency *= (1.1 + drand48());
            break;
            
        case TonalHarmonyConsonance:
            new_frequency = Interval(frequency, interval);
            break;
            
        case TonalHarmonyRandom:
            new_frequency = Tonality(frequency, interval, (TonalHarmony)arc4random_uniform(2));
            break;
            
        default:
            break;
    }
    
    return new_frequency;
}

typedef NS_ENUM(NSUInteger, TonalTrill) {
    TonalTrillUnsigned,
    TonalTrillInverse
};

static __inline__ double RandomDoubleBetween(double a, double b) {
    return a + (b - a) * ((double) random() / (double) RAND_MAX);
}

static inline double Frequency(double time, double frequency)
{
    return pow(sin(M_PI * time * frequency), 2.0);
}

static double(^TrillInterval)(double) = ^ double (double frequency) {
    return ((frequency / (max_frequency - min_frequency) * (max_trill_interval - min_trill_interval)) + min_trill_interval);
};

static double(^Trill)(double, double) = ^ double(double time, double trill)
{
    return pow(2.0 * pow(sin(M_PI * time * trill), 2.0) * 0.5, 4.0);
};

static double(^TrillInverse)(double, double) =  ^ double(double time, double trill)
{
    return pow(-(2.0 * pow(sin(M_PI * time * trill), 2.0) * 0.5) + 1.0, 4.0);
};

static double(^Amplitude)(double, double) = ^ double(double time, double frequency)
{
    return pow(sin(time * M_PI * frequency), 3.0);
};

static double(^Interval)(double, TonalInterval) = ^ double (double frequency, TonalInterval interval) {
    double new_frequency = frequency;
    switch (interval)
    {
        case TonalIntervalUnison:
            new_frequency *= 1.0;
            break;
            
        case TonalIntervalOctave:
            new_frequency *= 2.0;
            break;
            
        case TonalIntervalMajorSixth:
            new_frequency *= 5.0/3.0;
            break;
            
        case TonalIntervalPerfectFifth:
            new_frequency *= 4.0/3.0;
            break;
            
        case TonalIntervalMajorThird:
            new_frequency *= 5.0/4.0;
            break;
            
        case TonalIntervalMinorThird:
            new_frequency *= 6.0/5.0;
            break;
            
        case TonalIntervalRandom:
            new_frequency = Interval(frequency, (TonalInterval)arc4random_uniform(7));
            
        default:
            break;
    }
    
    return new_frequency;
};

typedef double (^FrequencySample)(double, double, double);
FrequencySample sample_frequency = ^(double time, double frequency, double trill)
{
    double result = sinf(M_PI * time * frequency) * ^ double (double * time_t, double * trill_t) {
        return (sinf(tau * (*time_t) * (*trill_t)) / 2); //((frequency / (2000.0 - 400.0) * (12.0 - 4.0)) + 4.0);
    } (&time, &trill);
    
    return result;
};

typedef double (^EnvelopeSample)(double, double, double);
EnvelopeSample envelope_sample = ^(double time, double gain, double tremolo)
{
    double result =  sinf((tau * time * tremolo) / 2) * (time * gain);
    
    return result;
};

static double gain_adjustment = 0;
typeof(gain_adjustment) * gain_adjustment_t = &gain_adjustment;

static AVAudioFramePosition frame = 0;
static AVAudioFramePosition * frame_t = &frame;
static simd_double1 n_time;
static simd_double1 * n_time_t = &n_time;

static typeof(simd_double1 *) normalized_times_ref = NULL;
static typeof(normalized_times_ref) (^normalized_times)(AVAudioFrameCount) = ^typeof(normalized_times_ref) (AVAudioFrameCount frame_count) {
    typedef simd_double1 normalized_time_type[frame_count];
    typeof(normalized_time_type) normalized_time;
    normalized_times_ref = &normalized_time[0];
    for (*frame_t = 0; *frame_t < frame_count; *frame_t += 1) {
        *(n_time_t) = 0.0 + ((((*frame_t - 0.0) * (1.0 - 0.0))) / (~-frame_count - 0.0));
        *(normalized_times_ref + *frame_t) = *(n_time_t);
    }
    
    return normalized_times_ref;
};


- (void)createAudioBufferWithFormat:(AVAudioFormat *)audioFormat completionBlock:(CreateAudioBufferCompletionBlock)createAudioBufferCompletionBlock
{
    static AVAudioPCMBuffer * (^createAudioBuffer)(double);
    createAudioBuffer = ^AVAudioPCMBuffer * (double frequency) {
        AVAudioFrameCount frame_count = audioFormat.sampleRate * (audioFormat.channelCount / RandomDoubleBetween(2, 4));
        AVAudioPCMBuffer * pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFormat frameCapacity:frame_count];
        pcmBuffer.frameLength = frame_count;
        float *left_channel  = pcmBuffer.floatChannelData[0];
        float *right_channel = (audioFormat.channelCount == 2) ? pcmBuffer.floatChannelData[1] : left_channel;
        
        double amplitude_frequency  = arc4random_uniform(4) + 2;
        double harmonized_frequency = Tonality(frequency, TonalIntervalRandom, TonalHarmonyRandom);
        
        normalized_times(frame_count);
        
        for (*frame_t = 0; *frame_t < frame_count; *frame_t += 1) {
            double amplitude        = sin(*(normalized_times_ref + *frame_t) * (tau * amplitude_frequency)); //Amplitude(*(normalized_times_ref + *frame_t), amplitude_frequency);
            double envelope         = amplitude * pow(sin(*(normalized_times_ref + *frame_t) * M_PI), 1.0 / (*(normalized_times_ref + *frame_t) * M_PI));
            left_channel[*frame_t]  = envelope * (1.0 * (Frequency(*(normalized_times_ref + *frame_t), frequency)));
            right_channel[*frame_t] = envelope * (1.0 * (Frequency(*(normalized_times_ref + *frame_t), harmonized_frequency)));
        }
        
        return pcmBuffer;
    };
    
    static void (^block)(void);
    block = ^{
        ({ createAudioBufferCompletionBlock(({ createAudioBuffer([self->_distributor nextInt]); }), ({ createAudioBuffer([self->_distributor nextInt]); }), ^{
            self->duration_bifurcate = [self->_distributor_duration nextInt];
            block();
        }); });
    };
    block();
}

@end
