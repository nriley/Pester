//
//  PSAlarmAlertController.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmAlertController.h"

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

- (id)initWithAlarm:(PSAlarm *)alarm;
{
    if ( (self = [super init]) != nil) {
        [[alarm alerts] makeObjectsPerformSelector: @selector(triggerForAlarm:)
                                        withObject: alarm];
        [NSApp activateIgnoringOtherApps: YES];
    }
    return self;
}

@end
