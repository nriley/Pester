//
//  PSUserNotificationAlert.m
//  Pester
//
//  Created by Nicholas Riley on 7/27/13.
//
//

#import "PSUserNotificationAlert.h"
#import "PSAlarmAlertController.h"

static PSUserNotificationAlert *PSUserNotificationAlertShared;

@implementation PSUserNotificationAlert

+ (BOOL)canTrigger;
{
#ifndef NSUserNotification
    Class NSUserNotification = NSClassFromString(@"NSUserNotification");
#endif

    return (NSUserNotification != NULL);
}

+ (PSAlert *)alert;
{
    if (PSUserNotificationAlertShared == nil) {
        PSUserNotificationAlertShared = [[PSUserNotificationAlert alloc] init];

        // XXX move into a separate class like Growl, if/when we can control the lifetime of alerts

#ifndef NSUserNotification
        Class NSUserNotificationCenter = NSClassFromString(@"NSUserNotificationCenter");
#endif

        id /*NSUserNotificationCenter*/ userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        [userNotificationCenter setDelegate: PSUserNotificationAlertShared];
    }

    return PSUserNotificationAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
#ifndef NSUserNotification
    Class NSUserNotification = NSClassFromString(@"NSUserNotification");
    Class NSUserNotificationCenter = NSClassFromString(@"NSUserNotificationCenter");
#endif

    if (NSUserNotification != nil) {
        id /*NSUserNotification*/ notification = [[NSUserNotification alloc] init];
        [notification setTitle: [alarm message]];
        [notification setSoundName: nil];
        [notification setActionButtonTitle: @"Stop Alerts"];

        id /*NSUserNotificationCenter*/ userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];

        [userNotificationCenter deliverNotification: notification];
        [notification release];
    }

    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Notify with OS X" small];
}

#pragma mark property list serialization (Pester 1.1)

- (instancetype)initWithPropertyList:(NSDictionary *)dict;
{
    [self release];
    return [[PSUserNotificationAlert alert] retain];
}

@end

@implementation PSUserNotificationAlert (NSUserNotificationCenterDelegate)

- (void)userNotificationCenter:(id /*NSUserNotificationCenter*/)center didActivateNotification:(id /*NSUserNotification*/)notification;
{
    if ([notification activationType] == NSUserNotificationActivationTypeActionButtonClicked)
        [PSAlarmAlertController stopAlerts: nil];
}

- (BOOL)userNotificationCenter:(id /*NSUserNotificationCenter*/)center shouldPresentNotification:(id /*NSUserNotification*/)notification;
{
    return YES;
}

@end