//
//  PSApplication.m
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSApplication.h"
#import "PSAlarmsController.h"
#import "PSAlarmNotifierController.h"
#import "PSAlarm.h"
#import "PSAlarms.h"

@implementation PSApplication

- (void)finishLaunching;
{
    [[NSNotificationCenter defaultCenter] addObserver: [PSAlarmNotifierController class] selector: @selector(controllerWithTimerExpiredNotification:) name: PSAlarmTimerExpiredNotification object: nil];
    [PSAlarms setUp];
    [super finishLaunching];
}

- (IBAction)orderFrontAlarmsPanel:(id)sender;
{
    if (alarmsController == nil) {
        alarmsController = [[PSAlarmsController alloc] init];
    }
    [alarmsController showWindow: self];
}

@end
