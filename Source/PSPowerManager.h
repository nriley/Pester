//
//  PSPowerManager.h
//  Pester
//
//  Created by Nicholas Riley on Mon Dec 23 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

extern NSString * const PSPowerManagerException;

@interface PSPowerManager : NSObject {
    id delegate;
    io_connect_t root_port;
    io_object_t notifier;
}

- (id)initWithDelegate:(id)aDelegate;

+ (BOOL)autoWakeSupported;
+ (void)setWakeTime:(NSDate *)time;
+ (void)clearWakeTime;

@end

@interface NSObject (PSPowerManagerDelegate)

- (void)powerManagerWillDemandSleep:(PSPowerManager *)powerManager;
- (BOOL)powerManagerShouldIdleSleep:(PSPowerManager *)powerManager;
- (void)powerManagerDidWake:(PSPowerManager *)powerManager;

@end