//
//  AVAudioSignal_ObjC.h
//  ToneBarrier
//
//  Created by Xcode Developer on 1/27/24.
//

//#ifndef AVAudioSignal_ObjC_h
//#define AVAudioSignal_ObjC_h
//
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>


@interface AVAudioSignal_ObjC : NSObject

- (AVAudioSourceNode *)createAudioSourceNodeWithFormat:(__strong AVAudioFormat *)audioFormat;


@end


//#endif /* AVAudioSignal_ObjC_h */
