//
//  PSAlarm.h
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PSAlarmInvalid, PSAlarmInterval, PSAlarmDate
} PSAlarmType;

@interface PSAlarm : NSObject {
    PSAlarmType alarmType;
    NSCalendarDate *alarmDate;
    NSTimeInterval alarmInterval;
    NSString *alarmMessage;
    NSString *invalidMessage;
}

- (void)setInterval:(NSTimeInterval)anInterval;
- (void)setForDateAtTime:(NSDate *)dateTime;
- (void)setForDate:(NSDate *)date atTime:(NSDate *)time;
- (void)setMessage:(NSString *)aMessage;

- (NSDate *)date;
- (NSTimeInterval)interval;

- (BOOL)isValid;
- (NSString *)message;
- (NSString *)invalidMessage;

@end
