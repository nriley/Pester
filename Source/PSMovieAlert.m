//
//  PSMovieAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <QuickTime/Movies.h>
#import "PSMovieAlert.h"
#import "PSMovieAlertController.h"
#import "NSMovie-NJRExtensions.h"

@implementation PSMovieAlert

+ (PSMovieAlert *)alertWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;
{
    return [[[self alloc] initWithAlias: anAlias repetitions: numReps] autorelease];
}

- (id)initWithAlias:(BDAlias *)anAlias repetitions:(unsigned int) numReps;
{
    if ( (self = [super init]) != nil) {
        alias = [anAlias retain];
        repetitions = numReps;
        movie = [[NSMovie alloc] initWithURL: [NSURL fileURLWithPath: [anAlias fullPath]] byReference: YES];
        if (movie == nil) {
            [self release];
            self = nil;
        } else {
            hasAudio = [movie hasAudio];
            hasVideo = [movie hasVideo];
            
            if (!hasAudio && !hasVideo) {
                [self release]; self = nil;
            }
        }
    }
    
    return self;
}

- (BOOL)hasVideo;
{
    return hasVideo;
}

- (NSMovie *)movie;
{
    return movie;
}

- (unsigned short)repetitions;
{
    return repetitions;
}

- (void)dealloc;
{
    [alias release];
    [movie release];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"PSMovieAlert (%@%@): %@, repeats %hu times", hasAudio ? @"A" : @"", hasVideo ? @"V" : @"", [alias fullPath], repetitions];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NSLog(@"%@", self);
    [PSMovieAlertController controllerWithAlarm: alarm movieAlert: self];
}

@end
