//
//  PSAlarm.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarm.h"

NSString * const PSAlarmTimerSetNotification = @"PSAlarmTimerSetNotification";
NSString * const PSAlarmTimerExpiredNotification = @"PSAlarmTimerExpiredNotification";

@implementation PSAlarm

- (void)dealloc;
{
    // NSLog(@"DEALLOC %@", self);
    alarmType = PSAlarmInvalid;
    [alarmDate release]; alarmDate = nil;
    [alarmMessage release]; alarmMessage = nil;
    [invalidMessage release]; invalidMessage = nil;
    [timer release]; timer = nil;
    [super dealloc];
}

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
    [self _setDateFromInterval];
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

- (void)setForDateAtTime:(NSCalendarDate *)dateTime;
{
    [self _setAlarmDate: dateTime];
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
    if (alarmType == PSAlarmDate) [self _setIntervalFromDate];
    return (alarmType != PSAlarmInvalid);
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
    if (invalidMessage == nil) return @"";
    return invalidMessage;
}

- (NSDate *)date;
{
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];
    return alarmDate;
}

- (NSTimeInterval)interval;
{
    if (alarmType == PSAlarmSet) return [timer timeInterval]; // XXX counts down?
    if (alarmType == PSAlarmDate) [self _setIntervalFromDate];
    return alarmInterval;
}

- (BOOL)setTimer;
{
    switch (alarmType) {
        case PSAlarmDate: if (![self isValid]) return NO;
        case PSAlarmInterval:
            timer = [NSTimer scheduledTimerWithTimeInterval: alarmInterval
                                                     target: self
                                                   selector: @selector(_timerExpired:)
                                                   userInfo: nil
                                                    repeats: NO];
            if (timer != nil) {
                alarmType = PSAlarmSet;
                [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmTimerSetNotification object: self];
                return YES;
            }
        default:
            return NO;
    }
}

- (void)cancel;
{
    [timer release]; timer = nil;
}

- (void)_timerExpired:(NSTimer *)aTimer;
{
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmTimerExpiredNotification object: self];
    timer = nil;
    [timer release];
}

- (NSString *)_alarmTypeString;
{
    switch (alarmType) {
        case PSAlarmDate: return @"PSAlarmDate";
        case PSAlarmInterval: return @"PSAlarmInterval";
        case PSAlarmSet: return @"PSAlarmSet";
        case PSAlarmInvalid: return @"PSAlarmInvalid";
        default: return [NSString stringWithFormat: @"<unknown: %u>", alarmType];
    }
}

- (NSComparisonResult)compare:(PSAlarm *)otherAlarm;
{
    return [[self date] compare: [otherAlarm date]];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"%@: type %@ date %@ interval %.1f%@",
        [super description], [self _alarmTypeString], alarmDate, alarmInterval,
        (alarmType == PSAlarmInvalid ?
         [NSString stringWithFormat: @"\ninvalid message: %@", invalidMessage]
        : (alarmType == PSAlarmSet ?
           [NSString stringWithFormat: @"\ntimer: %@", timer] : @""))];
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    if (![self isValid]) return;
    [coder encodeValueOfObjCType: @encode(PSAlarmType) at: &alarmType];
    switch (alarmType) {
        case PSAlarmDate:
        case PSAlarmSet:
            [coder encodeObject: alarmDate];
            break;
        case PSAlarmInterval:
            [coder encodeValueOfObjCType: @encode(NSTimeInterval) at: &alarmInterval];
            break;
        default:
            break;
    }
    [coder encodeObject: alarmMessage];
    return;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if ( (self = [super init]) != nil) {
        [coder decodeValueOfObjCType: @encode(PSAlarmType) at: &alarmType];
        switch (alarmType) {
            case PSAlarmDate:
            case PSAlarmSet:
                [self _setAlarmDate: [coder decodeObject]];
                break;
            case PSAlarmInterval:
                [coder decodeValueOfObjCType: @encode(NSTimeInterval) at: &alarmInterval];
                break;
            default:
                break;
        }
        [self setMessage: [coder decodeObject]];
        if (alarmType == PSAlarmSet) {
            alarmType = PSAlarmDate;
            [self setTimer];
        }
    }
    return self;
}

@end
