//
//  PSGrowlAlert.m
//  Pester
//
//  Created by Nicholas Riley on 8/24/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "PSAlarmAlertController.h"
#import "PSGrowlAlert.h"
#import "PSUserNotificationAlert.h"

@implementation PSGrowlAlert

+ (BOOL)canTrigger;
{
    return YES;
}

+ (PSAlert *)alert;
{
    return [PSUserNotificationAlert alert];
}

#pragma mark property list serialization (Pester 1.1)

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    [self release];
    return [[PSUserNotificationAlert alert] retain];
}

@end
