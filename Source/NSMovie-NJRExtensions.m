//
//  NSMovie-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
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

- (BOOL)isStatic;
{
    Movie movie = (Movie)[self QTMovie];
    long trackCount = (long)GetMovieTrackCount(movie);
    long trackIdx = 0;
    Track track;
    Media media;
    for (trackIdx = 1 ; trackIdx <= trackCount ; trackIdx++) {
        track = GetMovieIndTrack(movie, trackIdx);
        if (track == nil) continue;
        media = GetTrackMedia(track);
        if (media == nil) continue;
        if (GetMediaSampleCount(media) > 1) return NO;
    }
    return YES;
}

@end
