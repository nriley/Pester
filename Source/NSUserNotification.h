// 10.8+

@class NSString, NSDictionary, NSArray, NSDateComponents, NSDate, NSTimeZone, NSImage, NSAttributedString;
@protocol NSUserNotificationCenterDelegate;

typedef enum {
    NSUserNotificationActivationTypeNone = 0,
    NSUserNotificationActivationTypeContentsClicked = 1,
    NSUserNotificationActivationTypeActionButtonClicked = 2,
    NSUserNotificationActivationTypeReplied = 3 // 10.9
} NSUserNotificationActivationType;

@interface NSObject (NSUserNotification)
@property (copy) NSString *title;
@property (copy) NSString *subtitle;
@property (copy) NSString *informativeText;
@property (copy) NSString *actionButtonTitle;
@property (copy) NSDictionary *userInfo;
@property (copy) NSDate *deliveryDate;
@property (copy) NSTimeZone *deliveryTimeZone;
@property (copy) NSDateComponents *deliveryRepeatInterval;
@property (readonly) NSDate *actualDeliveryDate;
@property (readonly, getter=isPresented) BOOL presented;
@property (readonly, getter=isRemote) BOOL remote;
@property (copy) NSString *soundName;
@property BOOL hasActionButton;
@property (readonly) NSUserNotificationActivationType activationType;
@property (copy) NSString *otherButtonTitle;
@property (copy) NSString *identifier; // 10.9
@property (copy) NSImage *contentImage; // 10.9
@property BOOL hasReplyButton; // 10.9
@property (copy) NSString *responsePlaceholder; // 10.9
@property (readonly) NSAttributedString *response; // 10.9
@end

FOUNDATION_EXPORT NSString * const NSUserNotificationDefaultSoundName;

@interface NSObject (NSUserNotificationCenter)

+ (id /*NSUserNotificationCenter*/)defaultUserNotificationCenter;

@property (assign) id <NSUserNotificationCenterDelegate> delegate;

@property (copy) NSArray *scheduledNotifications;

- (void)scheduleNotification:(id /*NSUserNotification*/)notification;
- (void)removeScheduledNotification:(id /*NSUserNotification*/)notification;

@property (readonly) NSArray *deliveredNotifications;

- (void)deliverNotification:(id /*NSUserNotification*/)notification;
- (void)removeDeliveredNotification:(id /*NSUserNotification*/)notification;
- (void)removeAllDeliveredNotifications;

- (void)_removeAllPresentedAlerts; // 10.8; subsumed by removeAllDeliveredNotifications on 10.9

@end

@protocol NSUserNotificationCenterDelegate <NSObject>
@optional

- (void)userNotificationCenter:(id /*NSUserNotificationCenter*/)center didDeliverNotification:(id /*NSUserNotification*/)notification;

// Sent to the delegate when a user clicks on a notification in the notification center. This would be a good time to take action in response to user interacting with a specific notification.
// Important: If want to take an action when your application is launched as a result of a user clicking on a notification, be sure to implement the applicationDidFinishLaunching: method on your NSApplicationDelegate. The notification parameter to that method has a userInfo dictionary, and that dictionary has the NSApplicationLaunchUserNotificationKey key. The value of that key is the NSUserNotification that caused the application to launch. The NSUserNotification is delivered to the NSApplication delegate because that message will be sent before your application has a chance to set a delegate for the NSUserNotificationCenter.
- (void)userNotificationCenter:(id /*NSUserNotificationCenter*/)center didActivateNotification:(id /*NSUserNotification*/)notification;

- (BOOL)userNotificationCenter:(id /*NSUserNotificationCenter*/)center shouldPresentNotification:(id /*NSUserNotification*/)notification;

@end
