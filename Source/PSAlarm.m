//
//  PSAlarm.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarm.h"


@implementation PSAlarm

- (void)_setAlarmDate:(NSCalendarDate *)aDate;
{
    if (alarmDate != aDate) {
        [alarmDate release];
        alarmDate = nil;
        alarmDate = [aDate retain];
    }
}

- (void)_invalidate:(NSString *)aMessage;
{
    alarmType = PSAlarmInvalid;
    if (aMessage != invalidMessage) {
        [invalidMessage release];
        invalidMessage = nil;
        [self _setAlarmDate: nil];
        alarmInterval = 0;
        invalidMessage = [aMessage retain];
    }
}

- (void)_validateForType:(PSAlarmType)type;
{
    [invalidMessage release];
    invalidMessage = nil;
    alarmType = type;
}

- (void)_setDateFromInterval;
{
    [alarmDate release]; alarmDate = nil;
    alarmDate = [NSCalendarDate dateWithTimeIntervalSinceNow: alarmInterval];
    [alarmDate retain];
    [self _validateForType: PSAlarmInterval];
}

- (void)setInterval:(NSTimeInterval)anInterval;
{
    alarmInterval = anInterval;
    if (alarmInterval <= 0) {
        [self _invalidate: @"Please specify an alarm interval."]; return;
    }
}

- (void)_setIntervalFromDate;
{
    alarmInterval = [alarmDate timeIntervalSinceNow];
    if (alarmInterval <= 0) {
        [self _invalidate: @"Please specify an alarm time in the future."];
        return;
    }
    [self _validateForType: PSAlarmDate];
}

- (void)setForDateAtTime:(NSDate *)dateTime;
{
    if (dateTime != alarmDate) {
        [alarmDate release];
        alarmDate = nil;
        alarmDate = [dateTime retain];
    }
    [self _setIntervalFromDate];
}

- (void)setForDate:(NSDate *)date atTime:(NSDate *)time;
{
    NSCalendarDate *calTime, *calDate;
    if (time == nil && date == nil) {
        [self _invalidate: @"Please specify an alarm date and time."]; return;
    }
    if (time == nil) {
        [self _invalidate: @"Please specify an alarm time."]; return;
    }
    if (date == nil) {
        [self _invalidate: @"Please specify an alarm date."]; return;
    }
    // XXX if calTime's date is different from the default date, complain
    calTime = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [time timeIntervalSinceReferenceDate]];
    calDate = [NSCalendarDate dateWithTimeIntervalSinceReferenceDate: [date timeIntervalSinceReferenceDate]];
    if (calTime == nil || calDate == nil) {
        [self _invalidate: @"Please specify a reasonable date and time."];
    }
    [self setForDateAtTime:
        [[[NSCalendarDate alloc] initWithYear: [calDate yearOfCommonEra]
                                        month: [calDate monthOfYear]
                                          day: [calDate dayOfMonth]
                                         hour: [calTime hourOfDay]
                                       minute: [calTime minuteOfHour]
                                       second: [calTime secondOfMinute]
                                     timeZone: nil] autorelease]];
}

- (BOOL)isValid;
{
    return (alarmType == PSAlarmInvalid);
}

- (void)setMessage:(NSString *)aMessage;
{
    if (aMessage != alarmMessage) {
        [alarmMessage release];
        alarmMessage = nil;
        alarmMessage = [aMessage retain];
    }
}

- (NSString *)message;
{
    if (alarmMessage == nil || [alarmMessage isEqualToString: @""])
        return @"Alarm!";
    return alarmMessage;    
}

- (NSString *)invalidMessage;
{
    return invalidMessage;
}

- (NSDate *)date;
{
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];
    return alarmDate;
}

- (NSTimeInterval)interval;
{
    if (alarmType == PSAlarmDate) [self _setIntervalFromDate];
    return alarmInterval;
}

@end
