//
//  PSAlarmNotifierController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmNotifierController.h"
#import "PSAlarmAlertController.h"
#import "PSAlarm.h"

@implementation PSAlarmNotifierController

// XXX should use NSNonactivatingPanelMask on 10.2

- (id)initWithAlarm:(PSAlarm *)alarm;
{
    if ([self initWithWindowNibName: @"Notifier"]) {
        [[self window] center];
        [messageField setStringValue: [alarm message]];
        [dateField setStringValue:
            [NSString stringWithFormat: @"%@ at %@", [alarm dateString], [alarm timeString]]];
        [[self window] makeKeyAndOrderFront: nil];
        [[self window] orderFrontRegardless];
    }
    return self;
}

- (IBAction)close:(id)sender;
{
    [PSAlarmAlertController stopAlerts: sender];
    [self close];
}

@end
