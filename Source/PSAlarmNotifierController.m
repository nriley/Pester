//
//  PSAlarmNotifierController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmNotifierController.h"


@implementation PSAlarmNotifierController

- (id)initWithTimer:(NSTimer *)timer;
{
    if ([self initWithWindowNibName: @"Notifier"]) {
        NSString *message = [timer userInfo];

        [[self window] center];
        if (message == nil || [message isEqualToString: @""])
            message = @"Alarm!";
        [messageField setStringValue: message];
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
