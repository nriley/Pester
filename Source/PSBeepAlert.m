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
#import "NJRSoundManager.h"
#import "NSDictionary-NJRExtensions.h"

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSNumber

@implementation PSBeepAlert

+ (PSBeepAlert *)alertWithRepetitions:(unsigned short)numReps;
{
    return [[self alloc] initWithRepetitions: numReps];
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
        if (savedVolume) {
            [NJRSoundManager restoreSavedDefaultOutputVolumeIfCurrently: outputVolume];
        }
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
    savedVolume = [NJRSoundManager saveDefaultOutputVolume];
    [self beep];
}

- (NSAttributedString *)actionDescription;
{
    return // XXX [
        [[@"Play the system alert sound" stringByAppendingString:
                                             repetitions == 1 ? @"" : [NSString stringWithFormat: @" %hu times", repetitions]]
        // XXX stringByAppendingString: outputVolume == kNoVolume ? @"" : [NSString stringWithFormat: @" at %.0f%% volume", outputVolume * 100]]
            small];
}

@end
