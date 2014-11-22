//
//  PSUserNotificationAlert.m
//  Pester
//
//  Created by Nicholas Riley on 7/27/13.
//
//

#import "PSUserNotificationAlert.h"
#import "PSAlarms.h"
#import "PSAlarmAlertController.h"

static PSUserNotificationAlert *PSUserNotificationAlertShared;

@implementation PSUserNotificationAlert

+ (void)initialize;
{
    PSUserNotificationAlertShared = [[PSUserNotificationAlert alloc] init];

    // XXX move into a separate class like Growl, if/when we can control the lifetime of alerts
    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [userNotificationCenter setDelegate: PSUserNotificationAlertShared];

    [[NSNotificationCenter defaultCenter] addObserver: userNotificationCenter
                                             selector: @selector(removeAllDeliveredNotifications)
                                                 name: PSAlarmAlertStopNotification
                                               object: nil];
}

+ (PSAlert *)alert;
{
    return PSUserNotificationAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setTitle: [alarm message]];
    [notification setSoundName: nil];
    NSString *uuidString = [alarm uuidString];
    if ([alarm isRepeating]) {
        [notification setActionButtonTitle: @"Stop Repeating"];
        [notification setUserInfo: [NSDictionary dictionaryWithObject: uuidString forKey: @"uuid"]];
    } else {
        [notification setHasActionButton: NO];
    }
    [notification setIdentifier: uuidString];

    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];

    [userNotificationCenter deliverNotification: notification];
    [notification release];

    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Notify with OS X" small];
}

#pragma mark property list serialization (Pester 1.1)

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    [self release];
    return [[PSUserNotificationAlert alert] retain];
}

@end

@implementation PSUserNotificationAlert (NSUserNotificationCenterDelegate)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;
{
    if ([notification activationType] == NSUserNotificationActivationTypeActionButtonClicked) {
        [PSAlarmAlertController stopAlerts: nil];
        [[[PSAlarms allAlarms] alarmWithUUIDString: [[notification userInfo] objectForKey: @"uuid"]] setRepeating: NO];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification;
{
    return YES;
}

@end