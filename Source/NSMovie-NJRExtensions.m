//
//  NSMovie-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSMovie-NJRExtensions.h"
#import <QuickTime/Movies.h>

@implementation NSMovie (NJRExtensions)

- (BOOL)hasAudio;
{
    return (NULL != GetMovieIndTrackType((Movie)[self QTMovie], 1, AudioMediaCharacteristic, movieTrackCharacteristic | movieTrackEnabledOnly));
}

- (BOOL)hasVideo;
{
    return (NULL != GetMovieIndTrackType((Movie)[self QTMovie], 1, VisualMediaCharacteristic, movieTrackCharacteristic | movieTrackEnabledOnly));
}

@end
