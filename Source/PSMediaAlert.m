//
//  PSMediaAlert.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSMediaAlert.h"
#import "NSDictionary-NJRExtensions.h"
#import "NJRSoundManager.h"
#import <QuickTime/Movies.h>

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSString
static NSString * const PLAlertOutputVolume = @"volume"; // NSNumber

@implementation PSMediaAlert

#pragma mark initialize-release

- (id)initWithRepetitions:(unsigned short)numReps;
{
    if ( (self = [super init]) != nil) {
        repetitions = numReps;
    }
    return self;
}

#pragma mark accessing

- (unsigned short)repetitions;
{
    return repetitions;
}

- (float)outputVolume;
{
    return outputVolume;
}

- (void)setOutputVolume:(float)volume;
{
    if ([NJRSoundManager volumeIsNotMutedOrInvalid: volume])
        outputVolume = volume;
    else
        outputVolume = kNoVolume;
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *plAlert = [[super propertyListRepresentation] mutableCopy];
    [plAlert setObject: [NSNumber numberWithUnsignedShort: repetitions] forKey: PLAlertRepetitions];
    if (outputVolume != kNoVolume) {
        [plAlert setObject: [NSNumber numberWithFloat: outputVolume] forKey: PLAlertOutputVolume];
    }
    return [plAlert autorelease];
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self initWithRepetitions: [[dict objectForRequiredKey: PLAlertRepetitions] unsignedShortValue]]) != nil) {
        [self setOutputVolume: [[dict objectForKey: PLAlertOutputVolume] floatValue]];
    }
    return self;
}

@end
