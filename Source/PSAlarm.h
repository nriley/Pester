//
//  PSAlarm.h
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PSAlarmInvalid, PSAlarmInterval, PSAlarmDate, PSAlarmSet
} PSAlarmType;

extern NSString * const PSAlarmTimerSetNotification;
extern NSString * const PSAlarmTimerExpiredNotification;

// XXX figure out how to support reading old alarms

@class PSAlert;

@interface PSAlarm : NSObject <NSCoding> {
    PSAlarmType alarmType;
    NSCalendarDate *alarmDate;
    NSTimeInterval alarmInterval;
    NSString *alarmMessage;
    NSString *invalidMessage;
    NSTimer *timer;
    NSMutableArray *alerts;
}

- (void)setInterval:(NSTimeInterval)anInterval;
- (void)setForDateAtTime:(NSCalendarDate *)dateTime;
- (void)setForDate:(NSDate *)date atTime:(NSDate *)time;
- (void)setMessage:(NSString *)aMessage;
- (void)addAlert:(PSAlert *)alert;
- (void)removeAlerts;

- (NSCalendarDate *)date;
- (NSTimeInterval)interval;
- (NSString *)message;
- (NSArray *)alerts;

- (NSString *)dateString;
- (NSString *)shortDateString;
- (NSString *)timeString;
- (NSString *)timeRemainingString;

- (BOOL)isValid;
- (NSString *)invalidMessage;

- (NSComparisonResult)compare:(PSAlarm *)otherAlarm;

- (BOOL)setTimer;
- (void)cancel;

@end
