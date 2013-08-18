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

+ (BOOL)canTrigger;
{
    return YES;
}

+ (instancetype)alert;
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

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    if ( (self = [self init]) != nil) {
        @try {
            IMP myImp = [self methodForSelector: _cmd];
            NSString *clsString = [dict objectForRequiredKey: PLAlertClass];
            Class cls = NSClassFromString(clsString);
            NSAssert1(cls != nil, @"Alert class %@ is not available", clsString);
            [self release];
            self = [cls alloc];
            if (self != nil) {
                IMP subImp = [self methodForSelector: @selector(initWithPropertyList:error:)];
                NSAssert1(subImp != myImp, @"No implementation of initWithPropertyList:error: for alert class %@", clsString);
                self = [self initWithPropertyList: dict error: error];
            }
        } @catch (NSException *e) {
            [self release];
            @throw;
        }
    }
    return self;
}

@end
