//
//  PSAlarms.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const PSAlarmsDidChangeNotification;
extern NSString * const PSAlarmsNextAlarmDidChangeNotification;

@class PSAlarm;

@interface PSAlarms : NSObject {
    NSMutableArray *alarms;
    PSAlarm *nextAlarm;
}

+ (void)setUp;
+ (PSAlarms *)allAlarms;

- (PSAlarm *)nextAlarm;
- (int)alarmCount;
- (PSAlarm *)alarmAtIndex:(int)index;
- (void)removeAlarmAtIndex:(int)index;
- (void)removeAlarmsAtIndices:(NSArray *)indices;

@end