//
//  QTMovie-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "QTMovie-NJRExtensions.h"

@implementation QTMovie (NJRExtensions)

// at least on 10.5, QTMovie already implements undocumented "hasAudio" and "hasVideo"
- (BOOL)NJR_hasAudio;
{
    return [[self attributeForKey: QTMovieHasAudioAttribute] boolValue];
}

- (BOOL)NJR_hasVideo;
{
    return [[self attributeForKey: QTMovieHasVideoAttribute] boolValue];
}

- (BOOL)NJR_isStatic;
{
    NSEnumerator *e = [[self tracks] objectEnumerator];
    QTTrack *track;
    while ( (track = [e nextObject]) != nil)
	if ([[[track media] attributeForKey: QTMediaSampleCountAttribute] longValue] > 1)
	    return NO;
    return YES;
}

@end
