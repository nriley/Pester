//
//  PSAlarmNotifierController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmNotifierController.h"
#import "PSAlarm.h"

@implementation PSAlarmNotifierController

// XXX should use NSNonactivatingPanelMask on 10.2

+ (PSAlarmNotifierController *)controllerWithTimerExpiredNotification:(NSNotification *)notification;
{
    return [[self alloc] initWithAlarm: [notification object]];
}

- (id)initWithAlarm:(PSAlarm *)alarm;
{
    if ([self initWithWindowNibName: @"Notifier"]) {
        [[self window] center];
        [messageField setStringValue: [alarm message]];
        [dateField setObjectValue: [alarm date]];
        [NSApp activateIgnoringOtherApps: YES];
        [[self window] makeKeyAndOrderFront: nil];
        [[self window] orderFrontRegardless];
        NSBeep();
    }
    return self;
}

- (IBAction)close:(id)sender;
{
    [self close];
}

@end
