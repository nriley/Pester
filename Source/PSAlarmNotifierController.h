//
//  PSAlarmNotifierController.h
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NJRIntervalField;
@class PSAlarm;

@interface PSAlarmNotifierController : NSWindowController {
    IBOutlet NSTextField *messageField;
    IBOutlet NSTextField *dateField;
    IBOutlet NSTextField *intervalField;
    IBOutlet NSTextField *nextDateField;
    IBOutlet NJRIntervalField *snoozeIntervalField;
    IBOutlet NSButton *okButton;
    IBOutlet NSButton *snoozeButton;
    NSTimer *updateTimer;
    PSAlarm *alarm;
    BOOL canSnooze;
}

- (id)initWithAlarm:(PSAlarm *)anAlarm;

- (IBAction)close:(id)sender;
- (IBAction)snooze:(NSButton *)sender;
- (IBAction)stopRepeating:(NSButton *)sender;

@end
