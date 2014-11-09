//
//  PSAlarmAlertController.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSAlarm.h"

extern NSString * const PSAlarmAlertStopNotification;

@interface PSAlarmAlertController : NSObject {
    NSMutableSet *pendingAlerts;
    NSRunningApplication *frontmostApplication;
    BOOL appWasHidden;
}

+ (PSAlarmAlertController *)controllerWithTimerExpiredNotification:(NSNotification *)notification;

+ (void)stopAlerts:(id)sender;

- (id)initWithAlarm:(PSAlarm *)alarm;

@end

@interface NSObject (PSAlarmAlertWaitForIdle)

- (void)performAlertSelectorWhenIdle:(SEL)aSelector withObject:(id)anArgument;

@end
