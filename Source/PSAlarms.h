//
//  PSAlarms.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const PSAlarmsDidChangeNotification;

@class PSAlarm;

@interface PSAlarms : NSObject {
    NSMutableArray *alarms;
}

+ (void)setUp;
+ (PSAlarms *)allAlarms;

- (int)alarmCount;
- (PSAlarm *)alarmAtIndex:(int)index;
- (void)removeAlarmAtIndex:(int)index;
- (void)removeAlarmsAtIndices:(NSArray *)indices;

@end