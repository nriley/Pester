//
//  PSAlarm.h
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSPropertyListSerialization.h"

typedef enum {
    PSAlarmInvalid, // incorrectly specified
    PSAlarmInterval, // interval specified (possibly repeating)
    PSAlarmDate, // date specified
    PSAlarmSet, // pending, timer set
    PSAlarmSnooze, // expired alarm with snooze interval set (possibly repeating)
    PSAlarmExpired // expired alarm (possibly repeating)
} PSAlarmType;

extern NSString * const PSAlarmTimerSetNotification;
extern NSString * const PSAlarmTimerExpiredNotification;
extern NSString * const PSAlarmDiedNotification;

@class PSAlert, PSAlerts;

@interface PSAlarm : NSObject <NSCoding, PSPropertyListSerialization> {
    PSAlarmType alarmType; // changes during lifetime of alarm; more like a state
    NSCalendarDate *alarmDate;
    NSTimeInterval alarmInterval;
    NSTimeInterval snoozeInterval;
    NSTimeInterval timeRemaining;
    NSString *alarmMessage;
    NSString *invalidMessage;
    NSTimer *timer;
    PSAlerts *alerts;
    BOOL repeating;
}

- (void)setInterval:(NSTimeInterval)anInterval;
- (void)setForDateAtTime:(NSCalendarDate *)dateTime;
- (void)setForDate:(NSDate *)date atTime:(NSDate *)time;
- (void)setMessage:(NSString *)aMessage;
- (void)setAlerts:(PSAlerts *)theAlerts;
- (void)setRepeating:(BOOL)isRepeating;
- (void)setSnoozeInterval:(NSTimeInterval)anInterval;

- (NSCalendarDate *)date;
- (NSCalendarDate *)time;
- (NSTimeInterval)interval;
- (NSTimeInterval)timeRemaining;
- (NSString *)message;
- (PSAlerts *)alerts;
- (BOOL)isRepeating;
- (NSTimeInterval)snoozeInterval; // most recent interval (nonzero return does not indicate alarm is snoozing or set to snooze)

- (NSString *)dateString;
- (NSString *)shortDateString;
- (NSString *)timeString;
- (NSString *)dateTimeString; // current or next alarm time
- (NSString *)nextDateTimeString; // next alarm time
- (NSString *)intervalString;
- (NSString *)timeRemainingString;

- (BOOL)isValid;
- (NSString *)invalidMessage;

- (NSAttributedString *)prettyDescription;

- (NSComparisonResult)compareDate:(PSAlarm *)otherAlarm;
- (NSComparisonResult)compareMessage:(PSAlarm *)otherAlarm;

- (BOOL)setTimer; // or die, if expired and no snooze/repeat
- (void)cancelTimer;

// 1.1 only, going away when we move to keyed archiving
- (NSDictionary *)propertyListRepresentation;
- (id)initWithPropertyList:(NSDictionary *)dict;

@end
