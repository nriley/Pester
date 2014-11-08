//
//  PSBeepAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "PSBeepAlert.h"
#import "PSAlarmAlertController.h"
#import "NSDictionary-NJRExtensions.h"

@interface PSBeepAlert ()
- (void)beep;
@end

static void PSBeepAlertSoundCompleted(SystemSoundID ssID, void *self) {
    [(PSBeepAlert *)self beep];
}

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
    if (repetitionsRemaining == 0) {
	AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_UserPreferredAlert);
        [self completedForAlarm: alarm];
        [self release];
        return;
    }
    AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    repetitionsRemaining--;
}

- (void)_stopBeeping:(NSNotification *)notification;
{
    repetitionsRemaining = 0;
}

- (void)triggerForAlarm:(PSAlarm *)anAlarm;
{
    alarm = anAlarm;
    repetitionsRemaining = repetitions;
    [self retain];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopBeeping:) name: PSAlarmAlertStopNotification object: nil];
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_UserPreferredAlert, NULL, NULL, PSBeepAlertSoundCompleted, (void *)self);
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
