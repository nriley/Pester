//
//  PSAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlert.h"
#import "NSDictionary-NJRExtensions.h"

NSString * const PSAlertCreationException = @"PSAlertCreationException";

NSString * const PSAlarmAlertCompletedNotification = @"PSAlarmAlertCompletedNotification";

// property list keys
static NSString * const PLAlertClass = @"class"; // NSString

@implementation PSAlert

+ (PSAlert *)alert;
{
    NSAssert(NO, @"Class is abstract");
    return nil;
}

- (void)prepareForAlarm:(PSAlarm *)alarm;
{
    return;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NSAssert(NO, @"Class is abstract");
}

- (BOOL)requiresPesterFrontmost;
{
    return NO;
}

- (void)completedForAlarm:(PSAlarm *)alarm;
{
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmAlertCompletedNotification object: alarm userInfo: [NSDictionary dictionaryWithObject: self forKey: @"alert"]];
}

- (NSAttributedString *)actionDescription;
{
    NSAssert(NO, @"Class is abstract");
    return nil;
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    return [NSDictionary dictionaryWithObject: NSStringFromClass([self class]) forKey: PLAlertClass];
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self init]) != nil) {
        IMP myImp = [self methodForSelector: _cmd];
        NSString *clsString = [dict objectForRequiredKey: PLAlertClass];
        Class cls = NSClassFromString(clsString);
        NSAssert1(cls != nil, @"Alert class %@ is not available", clsString);
        [super release];
        self = [cls alloc];
        if (self != nil) {
            IMP subImp = [self methodForSelector: @selector(initWithPropertyList:)];
            NSAssert1(subImp != myImp, @"No implementation of initWithPropertyList: for alert class %@", clsString);
            self = [self initWithPropertyList: dict];
        }
    }
    return self;
}

@end
