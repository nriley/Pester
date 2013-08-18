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

+ (instancetype)alert;
{
    if (PSNotifierAlertShared == nil)
        PSNotifierAlertShared = [[PSNotifierAlert alloc] init];
    return PSNotifierAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [[PSAlarmNotifierController alloc] initWithAlarm: alarm];
}

- (BOOL)requiresPesterFrontmost;
{
    return YES;
}

- (NSAttributedString *)actionDescription;
{
    return [@"Display message and time" small];
}

#pragma mark property list serialization (Pester 1.1)

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    [self release];
    return [[PSNotifierAlert alert] retain];
}

@end
