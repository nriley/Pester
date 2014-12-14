//
//  PSAlarms.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSPropertyListSerialization.h"

extern NSString * const PSAlarmsDidChangeNotification;
extern NSString * const PSAlarmsNextAlarmDidChangeNotification;

@class PSAlarm;

@interface PSAlarms : NSObject <PSPropertyListSerialization> {
    NSMutableArray *alarms;
    NSMapTable *alarmsByUUID;
    NSMutableSet *expiredAlarms;
    PSAlarm *nextAlarm;
}

+ (void)setUp;
+ (PSAlarms *)allAlarms;

- (NSUInteger)countOfVersion1Alarms;
- (void)importVersion1Alarms;
- (void)discardVersion1Alarms;

- (NSArray *)alarms;

- (PSAlarm *)nextAlarm;
- (NSUInteger)alarmCount;
- (PSAlarm *)alarmWithUUIDString:(NSString *)uuidString;
- (void)removeAlarms:(NSSet *)alarmsToRemove;
- (void)restoreAlarms:(NSSet *)alarmsToRestore;

- (BOOL)alarmsExpiring;

@end

@interface NSObject (PSAlarmsNotifications)
- (void)nextAlarmDidChange:(NSNotification *)notification;
@end
