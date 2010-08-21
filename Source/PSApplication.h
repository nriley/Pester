//
//  PSApplication.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PSAlarm;
@class PSAlarmsController;
@class PSAlarmSetController;
@class PSTimer;
@class PSPreferencesController;

extern NSString * const PSApplicationWillReopenNotification;

@interface PSApplication : NSApplication {
    PSAlarmsController *alarmsController;
    IBOutlet PSAlarmSetController *alarmSetController;
    PSPreferencesController *preferencesController;
    PSTimer *dockUpdateTimer;
    NSTimeInterval dockUpdateInterval;
    NSImage *appIconImage;
}

- (IBAction)orderFrontSetAlarmPanel:(id)sender;
- (IBAction)orderFrontAlarmsPanel:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;
- (IBAction)stopAlerts:(id)sender;

- (void)orderFrontSetAlarmPanelIfPreferencesNotKey:(id)sender;

- (void)orderOutSetAlarmPanelIfHidden;

- (void)activateIgnoringOtherApps;

- (void)showTimeRemainingForAlarm:(PSAlarm *)alarm;

@end
