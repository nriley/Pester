//
//  PSNotifierAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSNotifierAlert.h"
#import "PSAlarmNotifierController.h"

static PSNotifierAlert *PSNotifierAlertShared;

@implementation PSNotifierAlert

+ (PSAlert *)alert;
{
    if (PSNotifierAlertShared == nil)
        PSNotifierAlertShared = [[PSNotifierAlert alloc] init];
    return PSNotifierAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [[PSAlarmNotifierController alloc] initWithAlarm: alarm];
}

@end
