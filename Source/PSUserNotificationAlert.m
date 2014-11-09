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

+ (BOOL)canTrigger;
{
    return (NSClassFromString(@"NSUserNotification") != NULL);
}

+ (void)initialize;
{
    PSUserNotificationAlertShared = [[PSUserNotificationAlert alloc] init];

    // XXX move into a separate class like Growl, if/when we can control the lifetime of alerts
    if (NSClassFromString(@"NSUserNotificationCenter") == nil)
        return;

    NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [userNotificationCenter setDelegate: PSUserNotificationAlertShared];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    void (^sendToUserNotificationCenterOnAlertStop)(SEL) = ^(SEL selector){
        if (![userNotificationCenter respondsToSelector: selector])
            return;

        [notificationCenter addObserver: userNotificationCenter
                               selector: selector
                                   name: PSAlarmAlertStopNotification
                                 object: nil];
    };

    // removes from Notification Center in 10.8; also removes alerts/banners in 10.9
    sendToUserNotificationCenterOnAlertStop(@selector(removeAllDeliveredNotifications));

    // -removeAllDeliveredNotifications doesn't remove alerts/banners in 10.8
    if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_8) {
        sendToUserNotificationCenterOnAlertStop(@selector(_removeAllPresentedAlerts)); // alerts
        // nothing, even SPI, for banners I can find in 10.8
    }
}

+ (PSAlert *)alert;
{
    return PSUserNotificationAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    if (NSClassFromString(@"NSUserNotification") != nil) {
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
        if ([notification respondsToSelector: @selector(setIdentifier:)]) // 10.9+
            [notification setIdentifier: uuidString];

        NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];

        [userNotificationCenter deliverNotification: notification];
        [notification release];
    }

    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    NSString *description = @"Notify with OS X";
    if (![PSUserNotificationAlert canTrigger])
        description = [description stringByAppendingString: @" (on OS X 10.8 Mountain Lion and later)"];

    return [description small];
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