//
//  PSAlarmsController.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSAlarms.h"

@interface PSAlarmsController : NSWindowController {
    IBOutlet NSTableView *alarmList;
    IBOutlet NSButton *removeButton;
    PSAlarms *alarms;
    NSArray *reorderedAlarms;
    NSDictionary *messageAttributes;
}

- (IBAction)remove:(id)sender;

- (void)selectAlarm:(PSAlarm *)alarm;

@end
