//
//  AVAsset-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "AVAsset-NJRExtensions.h"

@implementation AVAsset (NJRExtensions)

- (BOOL)NJR_hasAudio;
{
    return [[self tracksWithMediaType: AVMediaTypeAudio] count] > 0;
}

- (BOOL)NJR_hasVideo;
{
    return [[self tracksWithMediaType: AVMediaTypeVideo] count] > 0;
}

- (BOOL)NJR_isStatic;
{
    CMTime duration = self.duration;
    return (CMTIME_IS_NUMERIC(duration) && duration.value == 0); // XXX or indefinite?
}

@end
