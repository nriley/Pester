//
//  PSSnoozeUntilController.h
//  Pester
//
//  Created by Nicholas Riley on Sun Feb 16 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSAlarm.h"

@class PSAlarmNotifierController;

@interface PSSnoozeUntilController : NSWindowController {
    IBOutlet NSTextField *messageField;
    IBOutlet NSTextField *timeOfDay;
    IBOutlet NSTextField *timeDate;
    IBOutlet NSPopUpButton *timeDateCompletions; // XXX should go away when bug preventing both formatters and popup menus from existing is fixed
    IBOutlet NSButton *timeCalendarButton;
    IBOutlet NSButton *snoozeButton;
    NSTimeInterval snoozeInterval;
    PSAlarm *alarm; // not a real alarm, used for date<->interval conversion
}

+ (PSSnoozeUntilController *)snoozeUntilControllerWithNotifierController:(PSAlarmNotifierController *)aController;
- (id)initWithNotifierController:(PSAlarmNotifierController *)aController;

- (IBAction)update:(id)sender;
- (IBAction)dateCompleted:(NSPopUpButton *)sender;
- (IBAction)showCalendar:(NSButton *)sender;
- (IBAction)close:(id)sender;
- (IBAction)snooze:(NSButton *)sender;

@end
