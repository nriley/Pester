//
//  PSAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSAlarm.h"
#import "PSPropertyListSerialization.h"
#import "NSString-NJRExtensions.h"

extern NSString * const PSAlertCreationException;

extern NSString * const PSAlarmAlertCompletedNotification; // userInfo key: "alert" -> PSAlert

@interface PSAlert : NSObject <PSPropertyListSerialization> {
    
}

// subclasses should implement these methods
+ (PSAlert *)alert;
- (void)triggerForAlarm:(PSAlarm *)alarm;
- (BOOL)requiresPesterFrontmost;

- (NSAttributedString *)actionDescription;

// after alert completes, invoke method of superclass
- (void)completedForAlarm:(PSAlarm *)alarm;

@end
