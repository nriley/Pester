//
//  PSAlarmSetController.h
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface PSAlarmSetController : NSWindowController {
    IBOutlet NSTextField *messageField;
    IBOutlet NSMatrix *inAtMatrix;
    IBOutlet NSTextField *timeInterval;
    IBOutlet NSPopUpButton *timeIntervalUnits;
    IBOutlet NSTextField *timeOfDay;
    IBOutlet NSTextField *timeDate;
    IBOutlet NSPopUpButton *timeDateCompletions; // XXX should go away when bug preventing both formatters and popup menus from existing is fixed
    IBOutlet NSTextField *timeSummary;
    IBOutlet NSButton *setButton;
    NSString *status;
    BOOL isIn;
    NSCalendarDate *alarmDate;
    NSTimeInterval alarmInterval;
}

- (IBAction)update:(id)sender;
- (IBAction)dateCompleted:(NSPopUpButton *)sender;
- (IBAction)inAtChanged:(id)sender;
- (IBAction)setAlarm:(NSButton *)sender;

@end
