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

- (id)initWithTimer:(NSTimer *)timer;
{
    if ([self initWithWindowNibName: @"Notifier"]) {
        PSAlarm *alarm = [timer userInfo];

        [[self window] center];
        [messageField setStringValue: [alarm message]];
        [dateField setObjectValue: [timer fireDate]];
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
