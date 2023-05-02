//
//  PlayerCode.m
//  ToneBarrier
//
//  Created by Xcode Developer on 5/2/23.
//

#import <Foundation/Foundation.h>

__block AVAudioPlayerNodeChannelIndex player_node_channel_index;
            
            static void(^render_buffer[2])(AVAudioPlayerNodeIndex, dispatch_queue_t __strong, dispatch_queue_t __strong, AVAudioPlayerNode * __strong,  struct Randomizer *, struct Randomizer *, struct ToneDuration *);
            for (int i = 0; i < 2; i++)
            {
                duration_tally[i] = (struct ToneDuration *)malloc(sizeof(struct ToneDuration *));
                duration_tally[i]->tone_pair_duration = 2.0;
                
                frequency_chord = (struct FrequencyChord *)malloc(sizeof(struct FrequencyChord));
                //                frequency_chord->ratios[0] = 8.0;
                //                frequency_chord->ratios[0] = 10.0;
                //                frequency_chord->ratios[0] = 12.0;
                //                frequency_chord->ratios[0] = 15.0;
                
                render_buffer[i] = ^(AVAudioPlayerNodeIndex player_node_index, dispatch_queue_t __strong concurrent_queue, dispatch_queue_t __strong serial_queue, AVAudioPlayerNode * __strong player_node, struct Randomizer * duration_randomizer, struct Randomizer * frequency_randomizer, struct ToneDuration * tone_duration) {
                    ^(AVAudioPlayerNodeCount player_node_count, AVAudioSession * audio_session, AVAudioFormat * audio_format, BufferRenderedCompletionBlock buffer_rendered)
                    {
                        buffer_rendered(^ AVAudioPCMBuffer * (double distributed, double duration, void (^buffer_sample)(double, AVAudioFrameCount, double, double, StereoChannelOutput, float *)) {
//                            printf("\n%lu\t%sDUR:\t%f\tFREQ\t%f\n", time(0), (player_node_index == 0) ? [@"\t\t" UTF8String] : [@"" UTF8String], duration, distributed);
                            
                            double fundamental_frequency = distributed;
                            double harmonic_interval = (fundamental_frequency >= 1666) ? (5.0/6.0) : (6.0/5.0);
                            /*(player_node_index == 0) ?
                            ((fundamental_frequency >= 1600) ? (4.0/5.0) : (5.0/4.0)) :
                            ((fundamental_frequency >= 1000) ? (2.0/3.0) : (3.0/2.0));*/
                            double harmonic_frequency = fundamental_frequency * harmonic_interval;
                            
                            AVAudioFrameCount frameCount = ([audio_format sampleRate] * duration);
                            [player_node prepareWithFrameCount:frameCount];
                            AVAudioPCMBuffer *pcmBuffer  = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audio_format frameCapacity:frameCount];
                            pcmBuffer.frameLength        = frameCount;
                            AVAudioChannelCount channel_count = audio_format.channelCount;
                            
                            
                            buffer_sample(duration,
                                          frameCount,
                                          fundamental_frequency * duration,
                                          harmonic_frequency * duration,
                                          StereoChannelOutputLeft,
                                          pcmBuffer.floatChannelData[0]);
                            
                            player_node_channel_index = (player_node_channel_index + 1) % 4;
                            
                            buffer_sample(duration,
                                          frameCount,
                                          harmonic_frequency * duration,
                                          fundamental_frequency * duration,
                                          StereoChannelOutputRight,
                                          (channel_count == 2) ? pcmBuffer.floatChannelData[1] : nil);
                            
                            player_node_channel_index = (player_node_channel_index + 1) % 4;
                            
                            return pcmBuffer;
                        } (^ double (double random, uint32_t n, uint32_t m, double gamma) {
                            double result = pow(random, gamma);
                            result = (result * (m - n)) + n;
                            return result;
                        } (^ double () {
                            double random_num = drand48();
//                            random_num /= RAND_MAX;
                            return random_num;
                        } (), (player_node_index == 0) ? 400 : 1000, (player_node_index == 0) ? 900 : 2000, 1.0), ^ double (double * tally) {
                            if (*tally == 2.0)
                            {
                                double duration_diff = duration_randomizer->generate_distributed_random(duration_randomizer);
                                tone_duration->tone_pair_duration = 2.0 - duration_diff;
                                
                                return duration_diff;
                            } else {
                                double duration_remainder = tone_duration->tone_pair_duration;
                                tone_duration->tone_pair_duration = 2.0;
                                
                                return duration_remainder;
                            }
                        } (&tone_duration->tone_pair_duration), (^(double duration, AVAudioFrameCount sample_count, double fundamental_frequency, double harmonic_frequency, StereoChannelOutput stereo_channel_output, float * samples) {
                            double trill = ceil(0.00625 * fundamental_frequency);
                            
                            for (int index = 0; index < sample_count; index++)
                            if (samples) samples[index] =
                                ^ float (float xt, float frequency) { // pow(2.0 * pow(sinf(M_PI * time * trill), 2.0) * 0.5, 4.0);
                                    return sinf(M_PI * frequency * xt) * (^ float (void) {
                                        return sinf(2.0 * xt * M_PI * ((player_node_channel_index == 0 || player_node_channel_index == 2) ? trill - (xt * trill) : (xt * trill))) / (^ float (AVAudioChannelCount channel_count, AVAudioPlayerNodeCount player_node_count) {
                                            return ((^ float (float output_volume) { return (player_node_count * channel_count); } ((audio_session.outputVolume == 0) ? 1.0 : audio_session.outputVolume)));
                                                                                } (audio_format.channelCount, player_node_count));
                                                                            } ())
                                    // BEGIN
//                                    return (frequency < 600.0)
//                                    ? sinf(M_PI * frequency * xt) * (^ float (void) {
//                                        return sinf(M_PI * xt * ((((xt - 0.0) * (6.0 - 4.0)) / (1.0 - 0.0)))) * (^ float (AVAudioChannelCount channel_count, AVAudioPlayerNodeCount player_node_count) {
//                                            return ((^ float (float output_volume) { return /*sinf(M_PI * xt) / (2.0 * output_volume)*/ (1.0/output_volume) / (player_node_count * channel_count); } ((audio_session.outputVolume == 0) ? 1.0 : audio_session.outputVolume)));
//                                        } (audio_format.channelCount, player_node_count));
//                                    } ())
//                                    : cosf(M_PI * frequency * xt) * (^ float (void) {
//                                        return sinf(M_PI * xt * ((((xt - 0.0) * (6.0 - 4.0)) / (1.0 - 0.0)))) * (^ float (AVAudioChannelCount channel_count, AVAudioPlayerNodeCount player_node_count) {
//                                            return ((^ float (float output_volume) { return /*sinf(M_PI * xt) / (2.0 * output_volume)*/ (1.0/output_volume) / (player_node_count * channel_count); } ((audio_session.outputVolume == 0) ? 1.0 : audio_session.outputVolume)));
//                                        } (audio_format.channelCount, player_node_count));
//                                    } ())
                                    // END
                                    ;
                                } (^ float (float range_min, float range_max, float range_value) {
                                    return (range_value - range_min) / (range_max - range_min);
                                } (0.0, sample_count, index), fundamental_frequency);
                        })), ^{
                            dispatch_async(concurrent_queue, ^{
                                render_buffer[i](player_node_index, concurrent_queue, serial_queue, player_node, duration_randomizer, frequency_randomizer, tone_duration);
                            });
                        });
                    } ((AVAudioPlayerNodeCount)2, [AVAudioSession sharedInstance], self.audioFormat,
                       ^(AVAudioPCMBuffer * pcm_buffer, PlayedToneCompletionBlock played_tone) {
                        if ([player_node isPlaying])
                            [player_node scheduleBuffer:pcm_buffer atTime:nil options:AVAudioPlayerNodeBufferInterruptsAtLoop completionCallbackType:AVAudioPlayerNodeCompletionDataPlayedBack completionHandler:
                             ^(AVAudioPlayerNodeCompletionCallbackType callbackType) {
                                if (callbackType == AVAudioPlayerNodeCompletionDataPlayedBack)
                                /*dispatch_sync(serial_queue, ^{ */played_tone();/* });*/
                            }];
                    });
                };
                
                size_t buffer_length = 256;
                unsigned int seed = (unsigned int)time(0);
            
                char * _Nullable state_1 = malloc(sizeof(char) * buffer_length);
                initstate(seed, state_1, buffer_length);
                dispatch_async(player_nodes_concurrent_queue, ^{
                    srand((unsigned int)time(0));
                    struct Randomizer * duration_randomizer = (i == 0)
                    ? new_randomizer(random_generator_drand48, 1.25, 1.75, 1.0, random_distribution_gamma, 0.25, 1.75, 1.0)
                    : new_randomizer(random_generator_drand48, 0.25, 0.75, 1.0, random_distribution_gamma, 0.25, 1.75, 1.0);
                    struct Randomizer * frequency_randomizer = (i ==0)
                    ? new_randomizer(random_generator_drand48, 500.0, 2000.0, 1.0, random_distribution_gamma, 500.0, 1200.0, 3.0)
                    : new_randomizer(random_generator_drand48, 1000.0, 2000.0, 1.0, random_distribution_gamma, 1000.0, 2000.0, 1.0/3.0);
                    
                    
                    dispatch_sync((i == 0) ? player_node_serial_queue : player_node_serial_queue_aux, ^{
                        render_buffer[i](i, player_nodes_concurrent_queue,
                                         (i == 0) ? player_node_serial_queue : player_node_serial_queue_aux,
                                         (i == 0) ? self.playerNode : self.playerNodeAux,
                                         duration_randomizer,
                                         frequency_randomizer,
                                         ^struct ToneDuration * (struct ToneDuration * tally){ return tally; }(self->duration_tally[i]));
                    });
                });
            }wqq
