//
//  PSAlarm.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarm.h"
#import "PSAlert.h"
#import "NJRDateFormatter.h"

NSString * const PSAlarmTimerSetNotification = @"PSAlarmTimerSetNotification";
NSString * const PSAlarmTimerExpiredNotification = @"PSAlarmTimerExpiredNotification";

static NSString *dateFormat, *shortDateFormat, *timeFormat;
static NSDictionary *locale;

// XXX need to reset pending alarms after sleep, they "freeze" and never expire.

@implementation PSAlarm

+ (void)initialize; // XXX change on locale modification, subscribe to NSNotifications
{
    dateFormat = [[NJRDateFormatter localizedDateFormatIncludingWeekday: YES] retain];
    shortDateFormat = [[NJRDateFormatter localizedShortDateFormatIncludingWeekday: NO] retain];
    timeFormat = [[NJRDateFormatter localizedTimeFormatIncludingSeconds: YES] retain];
    locale = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] retain];
}

- (void)dealloc;
{
    // NSLog(@"DEALLOC %@", self);
    alarmType = PSAlarmInvalid;
    [alarmDate release]; alarmDate = nil;
    [alarmMessage release]; alarmMessage = nil;
    [invalidMessage release]; invalidMessage = nil;
    [timer invalidate]; [timer release]; timer = nil;
    [alerts release]; alerts = nil;
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
    if (alarmType == PSAlarmSet) return; // already valid
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
    alarmInterval = [alarmDate timeIntervalSinceNow] + 1;
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

- (NSCalendarDate *)date;
{
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];
    return alarmDate;
}

- (NSString *)dateString;
{
    return [[self date] descriptionWithCalendarFormat: dateFormat locale: locale];
}

- (NSString *)shortDateString;
{
    return [[self date] descriptionWithCalendarFormat: shortDateFormat locale: locale];
}

- (NSString *)timeString;
{
    return [[self date] descriptionWithCalendarFormat: timeFormat locale: locale];
}

- (NSString *)timeRemainingString;
{
    static const unsigned long long minute = 60, hour = minute * 60, day = hour * 24, year = day * 365.26;
    unsigned long long interval = [self interval];
    // +[NSString stringWithFormat:] in 10.1 does not support long longs: work around it by converting to unsigned ints or longs for display
    if (interval == 0) return @"ÇexpiredÈ";
    if (interval < minute) return [NSString stringWithFormat: @"%us", (unsigned)interval];
    if (interval < day) return [NSString stringWithFormat: @"%uh %um", (unsigned)(interval / hour), (unsigned)((interval % hour) / minute)];
    if (interval < year) return [NSString stringWithFormat: @"%u days", (unsigned)(interval / day)];
    if (interval < 2 * year) return @"One year";
    return [NSString stringWithFormat: @"%lu years", (unsigned long)(interval / year)];
}

- (NSTimeInterval)interval;
{
    if (alarmType == PSAlarmSet || alarmType == PSAlarmDate) [self _setIntervalFromDate];
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
                [timer retain];
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
    [timer invalidate]; [timer release]; timer = nil;
}

- (void)_timerExpired:(NSTimer *)aTimer;
{
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmTimerExpiredNotification object: self];
    [timer release]; timer = nil;
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

- (void)addAlert:(PSAlert *)alert;
{
    if (alerts == nil) alerts = [[NSMutableArray alloc] initWithCapacity: 4];
    [alerts addObject: alert];
}

- (void)removeAlerts;
{
    [alerts removeAllObjects];
}

- (NSArray *)alerts;
{
    return [[alerts copy] autorelease];
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
    // NSLog(@"encoded: %@", self); // XXX happening twice, gdb refuses to show proper backtrace, grr
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
