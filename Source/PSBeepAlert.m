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

- (void)beep;
{
    NSBeep();
    repetitionsRemaining--;
    if (repetitionsRemaining == 0) {
        [self release];
        return;
    }
    [self performSelector: @selector(beep) withObject: nil afterDelay: 0.15 inModes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (void)_stopBeeping:(NSNotification *)notification;
{
    repetitionsRemaining = 1;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    repetitionsRemaining = repetitions;
    [self retain];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopBeeping:) name: PSAlarmAlertStopNotification object: nil];
    [self beep];
}

@end
