//
//  PSBeepAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSBeepAlert.h"
#import "PSAlarmAlertController.h"
#import "NSDictionary-NJRExtensions.h"

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSNumber

@implementation PSBeepAlert

+ (PSBeepAlert *)alertWithRepetitions:(unsigned short)numReps;
{
    return [[self alloc] initWithRepetitions: numReps];
}

- (id)initWithRepetitions:(unsigned short)numReps;
{
    if ( (self = [super init]) != nil) {
        repetitions = numReps;
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

- (unsigned short)repetitions;
{
    return repetitions;
}

- (void)beep;
{
    NSBeep();
    repetitionsRemaining--;
    if (repetitionsRemaining == 0) {
        [self completedForAlarm: alarm];
        [self release];
        return;
    }
    [self performSelector: @selector(beep) withObject: nil afterDelay: 0.15 inModes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void)_stopBeeping:(NSNotification *)notification;
{
    repetitionsRemaining = 1;
}

- (void)triggerForAlarm:(PSAlarm *)anAlarm;
{
    alarm = anAlarm;
    repetitionsRemaining = repetitions;
    [self retain];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopBeeping:) name: PSAlarmAlertStopNotification object: nil];
    [self beep];
}

- (NSAttributedString *)actionDescription;
{
    return [[@"Play the system alert sound" stringByAppendingString:
                                            repetitions == 1 ? @"" : [NSString stringWithFormat: @" %hu times", repetitions]] small];
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *plAlert = [[super propertyListRepresentation] mutableCopy];
    [plAlert setObject: [NSNumber numberWithUnsignedShort: repetitions] forKey: PLAlertRepetitions];
    return [plAlert autorelease];
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    return [self initWithRepetitions: [[dict objectForRequiredKey: PLAlertRepetitions] unsignedShortValue]];
}

@end
