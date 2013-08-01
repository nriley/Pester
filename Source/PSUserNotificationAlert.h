//
//  PSUserNotificationAlert.h
//  Pester
//
//  Created by Nicholas Riley on 7/27/13.
//
//

#import "PSAlert.h"

#ifndef NSUserNotification
#import "NSUserNotification.h"
#endif

@interface PSUserNotificationAlert : PSAlert <NSUserNotificationCenterDelegate>

@end
