//
//  PSGrowlAlert.m
//  Pester
//
//  Created by Nicholas Riley on 8/24/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "PSAlarmAlertController.h"
#import "PSGrowlAlert.h"
#import "PSGrowlController.h"

static PSGrowlAlert *PSGrowlAlertShared;

@implementation PSGrowlAlert

+ (PSAlert *)alert;
{
    if (PSGrowlAlertShared == nil) {
        PSGrowlAlertShared = [[PSGrowlAlert alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:
         [PSGrowlController sharedController] selector: @selector(timeOutAllNotifications) name: PSAlarmAlertStopNotification object: nil];
    }
    
    return PSGrowlAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [[PSGrowlController sharedController] notifyWithTitle: [alarm message]
					      description: nil
					 notificationName: @"Alarm Expired"
						 isSticky: YES
						   target: self
						 selector: @selector(completedForAlarm:)
						   object: alarm
					      onlyOnClick: NO];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Notify with Growl" small];
}

#pragma mark property list serialization (Pester 1.1)

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    [self release];
    return [[PSGrowlAlert alert] retain];
}

@end
