//
//  PSAlarmAlertController.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmAlertController.h"
#import "PSAlert.h"
#import "PSAlerts.h"

NSString * const PSAlarmAlertStopNotification = @"PSAlarmAlertStopNotification";

@implementation PSAlarmAlertController

+ (PSAlarmAlertController *)controllerWithTimerExpiredNotification:(NSNotification *)notification;
{
    return [[[self alloc] initWithAlarm: [notification object]] autorelease];
}

+ (IBAction)stopAlerts:(id)sender;
{
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmAlertStopNotification object: nil];
}

- (void)_resumeAlarm:(PSAlarm *)alarm;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [alarm setTimer]; // if snooze not set and not repeating, alarm will die
    if (frontmostApp.highLongOfPSN != 0 || frontmostApp.lowLongOfPSN != 0) {
        SetFrontProcess(&frontmostApp);
        if (appWasHidden)
            [NSApp hide: self];
    }
}

- (void)_alertCompleted:(NSNotification *)notification;
{
    PSAlert *alert = [[notification userInfo] objectForKey: @"alert"];
    unsigned count = [pendingAlerts count];
    [pendingAlerts removeObject: alert];
    NSLog(@"removed: %@; still pending: %@", alert, [pendingAlerts description]);
    NSLog(@"alarm: %@ retainCount %d", [notification object], [[notification object] retainCount]);
    NSAssert2([pendingAlerts count] == count - 1, @"alert not in set: %@\n%@", alert, notification);
    if ([pendingAlerts count] == 0) {
        [self _resumeAlarm: [notification object]];
        [self release];
    }
}

- (id)initWithAlarm:(PSAlarm *)alarm;
{
    if ( (self = [super init]) != nil) {
        PSAlerts *alerts = [alarm alerts];
        NSArray *allAlerts = [alerts allAlerts];
        if ([allAlerts count] == 0) {
            [self _resumeAlarm: alarm];
        } else {
            pendingAlerts = [[NSMutableSet alloc] init];
            [pendingAlerts addObjectsFromArray: allAlerts];
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alertCompleted:)
                                                         name: PSAlarmAlertCompletedNotification object: alarm];
            [self retain]; // release in _alertCompleted:
        }
        [alerts triggerForAlarm: alarm];
        if ([alerts requirePesterFrontmost] && ![NSApp isActive]) { // restore frontmost process afterward
            NSDictionary *activeProcessInfo = [[NSWorkspace sharedWorkspace] activeApplication];
            frontmostApp.highLongOfPSN = [[activeProcessInfo objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue];
            frontmostApp.lowLongOfPSN = [[activeProcessInfo objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue];
            appWasHidden = [NSApp isHidden];
            [NSApp activateIgnoringOtherApps: YES];
        }
    }
    return self;
}

- (void)dealloc;
{
    NSLog(@"%@ dealloc", self);
    [pendingAlerts release];
    [super dealloc];
}

@end
