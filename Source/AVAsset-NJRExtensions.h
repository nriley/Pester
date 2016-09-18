//
//  AVAsset-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVAsset (NJRExtensions)

- (BOOL)NJR_hasAudio;
- (BOOL)NJR_hasVideo;
- (BOOL)NJR_isStatic;

@end
