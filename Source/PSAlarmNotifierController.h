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
    IBOutlet NSButton *stopRepeatingButton;
    NSTimer *updateTimer;
    PSAlarm *alarm;
    BOOL canSnooze;
    NSTimeInterval snoozeInterval;
    NSInteger lastValidIntervalMultiplierTag;
}

- (id)initWithAlarm:(PSAlarm *)anAlarm;

- (NSTimeInterval)snoozeInterval;
- (BOOL)setSnoozeInterval:(NSTimeInterval)interval;
- (void)snoozeUntilDate:(NSCalendarDate *)date;

- (IBAction)snoozeIntervalUnitsChanged:(NSPopUpButton *)sender;
- (IBAction)close:(id)sender;
- (IBAction)snooze:(NSButton *)sender;
- (IBAction)snoozeUntil:(NSMenuItem *)sender;
- (IBAction)stopRepeating:(id)sender;

@end
