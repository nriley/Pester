//
//  PSWakeAlert.m
//  Pester
//
//  Created by Nicholas Riley on Mon Jan 06 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSWakeAlert.h"
#import "PSPowerManager.h"

static PSWakeAlert *PSWakeAlertShared;

@implementation PSWakeAlert

+ (instancetype)alert;
{
    if (PSWakeAlertShared == nil)
        PSWakeAlertShared = [[PSWakeAlert alloc] init];
    return PSWakeAlertShared;
}

- (void)prepareForAlarm:(PSAlarm *)alarm;
{
    [alarm setWakeUp: YES];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Wake up computer if asleep" small];
}

#pragma mark property list serialization (Pester 1.1)

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    [self release];
    return [[PSWakeAlert alert] retain];
}

@end
