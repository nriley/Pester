// 10.8+

@class NSString, NSImage, NSAttributedString;
@protocol NSUserNotificationCenterDelegate;

/* typedef */ enum {
    NSUserNotificationActivationTypeReplied = 3 // 10.9
}; /* NSUserNotificationActivationType */

@interface NSObject (NSUserNotification)
@property (copy) NSString *identifier; // 10.9
@property (copy) NSImage *contentImage; // 10.9
@property BOOL hasReplyButton; // 10.9
@property (copy) NSString *responsePlaceholder; // 10.9
@property (readonly) NSAttributedString *response; // 10.9
@end

@interface NSObject (NSUserNotificationCenter)
- (void)_removeAllPresentedAlerts; // 10.8; subsumed by removeAllDeliveredNotifications on 10.9
@end
