//
//  PSAlarm.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarm.h"
#import "PSAlert.h"
#import "PSAlerts.h"
#import "PSTimer.h"
#import "NJRDateFormatter.h"
#import "NSCalendarDate-NJRExtensions.h"
#import "NSDictionary-NJRExtensions.h"
#import "NSString-NJRExtensions.h"

NSString * const PSAlarmTimerSetNotification = @"PSAlarmTimerSetNotification";
NSString * const PSAlarmTimerExpiredNotification = @"PSAlarmTimerExpiredNotification";
NSString * const PSAlarmDiedNotification = @"PSAlarmDiedNotification";

// property list keys
static NSString * const PLAlarmType = @"type"; // NSString
static NSString * const PLAlarmDate = @"date"; // NSNumber
static NSString * const PLAlarmInterval = @"interval"; // NSNumber
static NSString * const PLAlarmSnoozeInterval = @"snooze interval"; // NSNumber
static NSString * const PLAlarmMessage = @"message"; // NSString
static NSString * const PLAlarmAlerts = @"alerts"; // NSDictionary
static NSString * const PLAlarmRepeating = @"repeating"; // NSNumber

static NSString *dateFormat, *shortDateFormat, *timeFormat;
static NSDictionary *locale;

// XXX need to reset pending alarms after sleep, they "freeze" and never expire.

@implementation PSAlarm

#pragma mark initialize-release

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

#pragma mark private

- (void)_setAlarmDate:(NSCalendarDate *)aDate;
{
    if (alarmDate != aDate) {
        [alarmDate release];
        alarmDate = nil;
        alarmDate = [aDate retain];
    }
}

- (void)_beInvalid:(NSString *)aMessage;
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

- (void)_beValidWithType:(PSAlarmType)type;
{
    if (alarmType == PSAlarmSet) return; // already valid
    [invalidMessage release];
    invalidMessage = nil;
    alarmType = type;
    if (type != PSAlarmInterval) [self setRepeating: NO];
}

- (void)_setDateFromInterval;
{
    [self _setAlarmDate: [NSCalendarDate dateWithTimeIntervalSinceNow: alarmInterval]];
    [self _beValidWithType: PSAlarmInterval];
}

- (void)_setIntervalFromDate;
{
    alarmInterval = [alarmDate timeIntervalSinceNow];
    if (alarmInterval <= 0) {
        [self _beInvalid: @"Please specify an alarm time in the future."];
        return;
    }
    [self _beValidWithType: PSAlarmDate];
}

- (PSAlarmType)_alarmTypeForString:(NSString *)string;
{
    if ([string isEqualToString: @"PSAlarmDate"]) return PSAlarmDate;
    if ([string isEqualToString: @"PSAlarmInterval"]) return PSAlarmInterval;
    if ([string isEqualToString: @"PSAlarmSet"]) return PSAlarmSet;
    if ([string isEqualToString: @"PSAlarmInvalid"]) return PSAlarmInvalid;
    if ([string isEqualToString: @"PSAlarmSnooze"]) return PSAlarmSnooze;
    if ([string isEqualToString: @"PSAlarmExpired"]) return PSAlarmExpired;
    NSLog(@"unknown alarm type string: %@", string);
    return nil;
}

- (NSString *)_alarmTypeString;
{
    switch (alarmType) {
        case PSAlarmDate: return @"PSAlarmDate";
        case PSAlarmInterval: return @"PSAlarmInterval";
        case PSAlarmSet: return @"PSAlarmSet";
        case PSAlarmInvalid: return @"PSAlarmInvalid";
        case PSAlarmSnooze: return @"PSAlarmSnooze";
        case PSAlarmExpired: return @"PSAlarmExpired";
        default: return [NSString stringWithFormat: @"<unknown: %u>", alarmType];
    }
}

- (NSString *)_stringForInterval:(unsigned long long)interval;
{
    const unsigned long long minute = 60, hour = minute * 60, day = hour * 24, year = day * 365.26;
    // +[NSString stringWithFormat:] in 10.1 does not support long longs: work around it by converting to unsigned ints or longs for display
    if (interval == 0) return nil;
    if (interval < minute) return [NSString stringWithFormat: @"%us", (unsigned)interval];
    if (interval < day) return [NSString stringWithFormat: @"%uh %um", (unsigned)(interval / hour), (unsigned)((interval % hour) / minute)];
    if (interval < 2 * day) return @"One day";
    if (interval < year) return [NSString stringWithFormat: @"%u days", (unsigned)(interval / day)];
    if (interval < 2 * year) return @"One year";
    return [NSString stringWithFormat: @"%lu years", (unsigned long)(interval / year)];
}

- (void)_timerExpired:(PSTimer *)aTimer;
{
    NSLog(@"expired: %@; now %@", [[aTimer fireDate] description], [[NSDate date] description]);
    alarmType = PSAlarmExpired;
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmTimerExpiredNotification object: self];
    [timer release]; timer = nil;
}

#pragma mark alarm setting

- (void)setInterval:(NSTimeInterval)anInterval;
{
    alarmInterval = anInterval;
    if (alarmInterval <= 0) {
        [self _beInvalid: @"Please specify an alarm interval."]; return;
    }
    [self _setDateFromInterval];
}

- (void)setForDateAtTime:(NSCalendarDate *)dateTime;
{
    [self _setAlarmDate: dateTime];
    [self _setIntervalFromDate];
}

- (void)setForDate:(NSDate *)date atTime:(NSDate *)time;
{
    NSCalendarDate *dateTime;
    if (time == nil && date == nil) {
        [self _beInvalid: @"Please specify an alarm date and time."]; return;
    }
    if (time == nil) {
        [self _beInvalid: @"Please specify an alarm time."]; return;
    }
    if (date == nil) {
        [self _beInvalid: @"Please specify an alarm date."]; return;
    }
    // XXX if calTime's date is different from the default date, complain
    dateTime = [NSCalendarDate dateWithDate: date atTime: time];
    if (dateTime == nil) {
        [self _beInvalid: @"Please specify a reasonable date and time."];
    }
    [self setForDateAtTime: dateTime];
}

- (void)setRepeating:(BOOL)isRepeating;
{
    repeating = isRepeating;
}

- (void)setSnoozeInterval:(NSTimeInterval)anInterval;
{
    snoozeInterval = anInterval;
    NSAssert(alarmType == PSAlarmExpired, NSLocalizedString(@"Can't snooze an alarm that hasn't expired", "Assertion for PSAlarm snooze setting"));
    alarmType = PSAlarmSnooze;
}

- (void)setWakeUp:(BOOL)doWake;
{
    [timer setWakeUp: doWake];
}

#pragma mark accessing

- (NSString *)message;
{
    if (alarmMessage == nil || [alarmMessage isEqualToString: @""])
        return @"Alarm!";
    return alarmMessage;
}

- (void)setMessage:(NSString *)aMessage;
{
    if (aMessage != alarmMessage) {
        [alarmMessage release];
        alarmMessage = nil;
        alarmMessage = [aMessage retain];
    }
}

- (BOOL)isValid;
{
    if (alarmType == PSAlarmDate) [self _setIntervalFromDate];
    if (alarmType == PSAlarmInvalid ||
        (alarmType == PSAlarmExpired && ![self isRepeating])) return NO;
    return YES;
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

- (NSCalendarDate *)time;
{
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];
    return [[NSCalendarDate alloc] initWithYear: 0
                                          month: 1
                                            day: 1
                                           hour: [alarmDate hourOfDay]
                                         minute: [alarmDate minuteOfHour]
                                         second: [alarmDate secondOfMinute]
                                       timeZone: nil];
}

- (NSTimeInterval)interval;
{
    if (alarmType == PSAlarmDate) [self _setIntervalFromDate];
    return alarmInterval;
}

- (NSTimeInterval)snoozeInterval;
{
    return snoozeInterval;
}

- (NSTimeInterval)timeRemaining;
{
    NSAssert1(alarmType == PSAlarmSet, NSLocalizedString(@"Can't get time remaining on alarm with no timer set: %@", "Assertion for PSAlarm time remaining, internal error; %@ replaced by alarm description"), self);
    return -[[NSDate date] timeIntervalSinceDate: alarmDate];
}

- (void)setAlerts:(PSAlerts *)theAlerts;
{
    [alerts release]; alerts = nil;
    alerts = [theAlerts retain];
}

- (PSAlerts *)alerts;
{
    if (alerts == nil) alerts = [[PSAlerts alloc] init];
    return alerts;
}

- (BOOL)isRepeating;
{
    return repeating;
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

- (NSString *)dateTimeString;
{
    return [NSString stringWithFormat: @"%@ at %@", [self dateString], [self timeString]];
}

- (NSString *)nextDateTimeString;
{
    if (![self isRepeating]) {
        return nil;
    } else {
        NSCalendarDate *date = [[NSCalendarDate alloc] initWithTimeIntervalSinceNow: [self interval]];
        NSString *nextDateTimeString = [NSString stringWithFormat: @"%@ at %@",
            [date descriptionWithCalendarFormat: dateFormat locale: locale],
            [date descriptionWithCalendarFormat: timeFormat locale: locale]];
        [date release];
        return nextDateTimeString;
    }
}

- (NSString *)intervalString;
{
    const unsigned long long mval = 99, minute = 60, hour = minute * 60;
    unsigned long long interval = [self interval];
    if (interval == 0) return nil;
    if (interval == 1) return @"One second";
    if (interval == minute) return @"One minute";
    if (interval % minute == 0) return [NSString stringWithFormat: @"%u minutes", (unsigned)(interval / minute)];
    if (interval <= mval) return [NSString stringWithFormat: @"%u seconds", (unsigned)interval];
    if (interval == hour) return @"One hour";
    if (interval % hour == 0) return [NSString stringWithFormat: @"%u hours", (unsigned)(interval / hour)];
    if (interval <= mval * minute) return [NSString stringWithFormat: @"%u minutes", (unsigned)(interval / minute)];
    if (interval <= mval * hour) return [NSString stringWithFormat: @"%u hours", (unsigned)(interval / hour)];
    return [self _stringForInterval: interval];
}

- (NSString *)timeRemainingString;
{
    NSString *timeRemainingString = [self _stringForInterval: llround([self timeRemaining])];
    
    if (timeRemainingString == nil) return @"ÇexpiredÈ";
    return timeRemainingString;
}

- (NSAttributedString *)prettyDescription;
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSAttributedString *alertList = [alerts prettyList];

    [string appendAttributedString:
        [[NSString stringWithFormat: NSLocalizedString(@"At alarm time for %@:\n", "Alert list title in pretty description, %@ replaced with message"), [self message]] small]];
    if (alertList != nil) {
        [string appendAttributedString: alertList];
    } else {
        [string appendAttributedString: [@"Do nothing." small]];
    }
    if ([self isRepeating]) {
        [string appendAttributedString:
            [[NSString stringWithFormat: @"\nAlarm repeats every %@.", [[self intervalString] lowercaseString]] small]];
    }
    return [string autorelease];
}

#pragma mark actions

- (BOOL)setTimer;
{
    if (alarmType == PSAlarmExpired) {
        if ([self isRepeating]) {
            [self _setDateFromInterval];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmDiedNotification object: self];
            return NO;
        }
    } else if (alarmType == PSAlarmDate) {
        if (![self isValid]) return NO;
    } else if (alarmType == PSAlarmSnooze) {
        [self _setAlarmDate: [NSCalendarDate dateWithTimeIntervalSinceNow: snoozeInterval]];
    } else if (alarmType != PSAlarmInterval) {
        return NO;
    }
    timer = [PSTimer scheduledTimerWithTimeInterval: (alarmType == PSAlarmSnooze ? snoozeInterval : alarmInterval) target: self selector: @selector(_timerExpired:) userInfo: nil repeats: NO];
    if (timer == nil) return NO;
    [timer retain];
    alarmType = PSAlarmSet;
    [alerts prepareForAlarm: self];

    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmTimerSetNotification object: self];
    // NSLog(@"set: %@; now %@; remaining %@", [[timer fireDate] description], [[NSDate date] description], [self timeRemainingString]);
    return YES;
}

- (void)cancelTimer;
{
    [timer invalidate]; [timer release]; timer = nil;
    [self setRepeating: NO];
}

#pragma mark comparing

- (NSComparisonResult)compareDate:(PSAlarm *)otherAlarm;
{
    return [[self date] compare: [otherAlarm date]];
}

- (NSComparisonResult)compareMessage:(PSAlarm *)otherAlarm;
{
    return [[self message] caseInsensitiveCompare: [otherAlarm message]];
}

#pragma mark printing

- (NSString *)description;
{
    return [NSString stringWithFormat: @"%@: type %@ date %@ interval %.1f%@",
        [super description], [self _alarmTypeString], alarmDate, alarmInterval,
        (alarmType == PSAlarmInvalid ?
         [NSString stringWithFormat: @"\ninvalid message: %@", invalidMessage]
        : (alarmType == PSAlarmSet ?
           [NSString stringWithFormat: @"\ntimer: %@", timer] : @""))];
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity: 5];
    if (![self isValid]) return nil;
    [dict setObject: [self _alarmTypeString] forKey: PLAlarmType];
    switch (alarmType) {
        case PSAlarmDate:
        case PSAlarmSet:
            [dict setObject: [NSNumber numberWithDouble: [alarmDate timeIntervalSinceReferenceDate]] forKey: PLAlarmDate];
            break;
        case PSAlarmSnooze:
        case PSAlarmInterval:
        case PSAlarmExpired:
            [dict setObject: [NSNumber numberWithDouble: alarmInterval] forKey: PLAlarmInterval];
            [dict setObject: [NSNumber numberWithBool: repeating] forKey: PLAlarmRepeating];
            break;
        default:
            NSAssert1(NO, NSLocalizedString(@"Can't save alarm type %@", "Assertion for invalid PSAlarm type on string; %@ replaced with alarm type string"), [self _alarmTypeString]);
            break;
    }
    if (snoozeInterval != 0)
        [dict setObject: [NSNumber numberWithDouble: snoozeInterval] forKey: PLAlarmSnoozeInterval];
    [dict setObject: alarmMessage forKey: PLAlarmMessage];
    if (alerts != nil) {
        [dict setObject: [alerts propertyListRepresentation] forKey: PLAlarmAlerts];
    }
    return dict;
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self init]) != nil) {
        PSAlerts *alarmAlerts;
        alarmType = [self _alarmTypeForString: [dict objectForRequiredKey: PLAlarmType]];
        switch (alarmType) {
            case PSAlarmDate:
            case PSAlarmSet:
               { NSCalendarDate *date = [[NSCalendarDate alloc] initWithTimeIntervalSinceReferenceDate: [[dict objectForRequiredKey: PLAlarmDate] doubleValue]];
                [self _setAlarmDate: date];
                [date release];
               }
                break;
            case PSAlarmSnooze: // snooze interval set but not confirmed; ignore
                alarmType = PSAlarmExpired;
            case PSAlarmInterval:
            case PSAlarmExpired:
                alarmInterval = [[dict objectForRequiredKey: PLAlarmInterval] doubleValue];
                repeating = [[dict objectForRequiredKey: PLAlarmRepeating] boolValue];
                break;
            default:
                NSAssert1(NO, NSLocalizedString(@"Can't load alarm type %@", "Assertion for invalid PSAlarm type on load; %@ replaced with alarm type string"), [self _alarmTypeString]);
                break;
        }
        snoozeInterval = [[dict objectForKey: PLAlarmSnoozeInterval] doubleValue];
        [self setMessage: [dict objectForRequiredKey: PLAlarmMessage]];
        alarmAlerts = [[PSAlerts alloc] initWithPropertyList: [dict objectForRequiredKey: PLAlarmAlerts]];
        [self setAlerts: alarmAlerts];
        [alarmAlerts release];
        if (alarmType == PSAlarmSet) {
            alarmType = PSAlarmDate;
            [self setTimer];
        }
        if (alarmType == PSAlarmExpired) {
            [self setTimer];
            if (alarmType == PSAlarmExpired) { // failed to restart
                [self release];
                self = nil;
            }
        }
    }
    return self;
}

#pragma mark archiving (Pester 1.0)

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
    if ( (self = [self init]) != nil) {
        PSAlerts *legacyAlerts = [[PSAlerts alloc] initWithPesterVersion1Alerts];
        [self setAlerts: legacyAlerts];
        [legacyAlerts release];
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
