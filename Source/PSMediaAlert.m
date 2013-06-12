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

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSString
static NSString * const PLAlertOutputVolume = @"volume"; // NSNumber

const float PSMediaAlertNoVolume = 0;

@implementation PSMediaAlert

#pragma mark initialize-release

- (id)initWithRepetitions:(unsigned short)numReps;
{
    if ( (self = [super init]) != nil) {
	// XXX not DRY, but can't think of a more sensible way
 	if (numReps < 1)
	    numReps = 1;
	else if (numReps > 99)
	    numReps = 99;
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
        outputVolume = PSMediaAlertNoVolume;
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *plAlert = [[super propertyListRepresentation] mutableCopy];
    [plAlert setObject: [NSNumber numberWithUnsignedShort: repetitions] forKey: PLAlertRepetitions];
    if (outputVolume != PSMediaAlertNoVolume) {
        [plAlert setObject: [NSNumber numberWithFloat: outputVolume] forKey: PLAlertOutputVolume];
    }
    return [plAlert autorelease];
}

- (instancetype)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self initWithRepetitions: [[dict objectForRequiredKey: PLAlertRepetitions] unsignedShortValue]]) != nil) {
        [self setOutputVolume: [[dict objectForKey: PLAlertOutputVolume] floatValue]];
    }
    return self;
}

@end
