//
//  PSApplication.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PSAlarmsController;
@class PSAlarmSetController;

@interface PSApplication : NSApplication {
    PSAlarmsController *alarmsController;
    IBOutlet PSAlarmSetController *alarmSetController;
    NSTimer *dockUpdateTimer;
    NSTimeInterval dockUpdateInterval;
    NSImage *appIconImage;
}

- (IBAction)orderFrontSetAlarmPanel:(id)sender;
- (IBAction)orderFrontAlarmsPanel:(id)sender;

@end
