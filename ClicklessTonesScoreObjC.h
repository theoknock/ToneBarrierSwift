//
//  ClicklessTonesScoreObjC.h
//  ToneBarrier
//
//  Created by Xcode Developer on 9/23/23.
//

#ifndef ClicklessTonesScoreObjC_h
#define ClicklessTonesScoreObjC_h

NS_ASSUME_NONNULL_BEGIN

#define max_frequency              1500.0
#define min_frequency               100.0
#define max_trill_interval            3.0
#define min_trill_interval            1.0
#define duration_interval             5.0
#define duration_maximum              2.0
#define tau                    M_PI * 2.0

@interface ClicklessTonesScoreObjC : NSObject

@end

NS_ASSUME_NONNULL_END



#endif /* ClicklessTonesScoreObjC_h */
