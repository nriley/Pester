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
    NSMutableSet *expiredAlarms;
    PSAlarm *nextAlarm;
}

+ (void)setUp;
+ (PSAlarms *)allAlarms;

- (unsigned)countOfVersion1Alarms;
- (void)importVersion1Alarms;
- (void)discardVersion1Alarms;

- (NSArray *)alarms;

- (PSAlarm *)nextAlarm;
- (int)alarmCount;
- (PSAlarm *)alarmAtIndex:(int)index;
- (void)removeAlarmAtIndex:(int)index;
- (void)removeAlarmsAtIndices:(NSArray *)indices;
- (void)removeAlarms:(NSSet *)alarmsToRemove;

- (BOOL)alarmsExpiring;

@end