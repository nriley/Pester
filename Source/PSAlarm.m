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

static NSDateFormatter *dateFormatter, *shortDateFormatter, *timeFormatter;

static NSCalendar *gregorianCalendar;

static NSDate *midnightOnDate(NSDate *date) {
    return [gregorianCalendar dateFromComponents: 
	    [gregorianCalendar components: NSMonthCalendarUnit|NSDayCalendarUnit|NSYearCalendarUnit fromDate: date]];
}

@implementation PSAlarm

#pragma mark initialize-release

+ (void)initialize;
{
    [NSDateFormatter setDefaultFormatterBehavior: NSDateFormatterBehavior10_4];
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    [dateFormatter setDateStyle: NSDateFormatterFullStyle];
    shortDateFormatter = [[NSDateFormatter alloc] init];
    [shortDateFormatter setTimeStyle: NSDateFormatterNoStyle];
    [shortDateFormatter setDateStyle: NSDateFormatterShortStyle];
    timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setTimeStyle: NSDateFormatterMediumStyle];
    [timeFormatter setDateStyle: NSDateFormatterNoStyle];
    gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
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
    return PSAlarmInvalid;
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
    if (interval % minute != 0) interval += minute; // match per-minute dock update interval
    if (interval < hour) return [NSString stringWithFormat: @"%um", (unsigned)(interval / minute)];
    if (interval < day) return [NSString stringWithFormat: @"%uh %um", (unsigned)(interval / hour), (unsigned)((interval % hour) / minute)];
    if (interval < 2 * day) return @"One day";
    if (interval < year) return [NSString stringWithFormat: @"%u days", (unsigned)(interval / day)];
    if (interval < 2 * year) return @"One year";
    return [NSString stringWithFormat: @"%lu years", (unsigned long)(interval / year)];
}

- (void)_timerExpired:(PSTimer *)aTimer;
{
    // NSLog(@"expired: %@; now %@", [[aTimer fireDate] description], [[NSDate date] description]);
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

- (void)setForDate:(NSDate *)aDate atTime:(NSDate *)aTime;
{
    NSCalendarDate *dateTime;
    if (aTime == nil && aDate == nil) {
        [self _beInvalid: @"Please specify an alarm date and time."]; return;
    }
    if (aTime == nil) {
        [self _beInvalid: @"Please specify an alarm time."]; return;
    }
    if (aDate == nil) {
        [self _beInvalid: @"Please specify an alarm date."]; return;
    }
    // XXX if calTime's date is different from the default date, complain
    dateTime = [NSCalendarDate dateWithDate: aDate atTime: aTime];
    if (dateTime == nil) {
        [self _beInvalid: @"Please specify a reasonable date and time."]; return;
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

- (NSDate *)midnightOnDate;
{
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];
    
    return midnightOnDate(alarmDate);
}

- (NSDate *)time;
{
    // XXX this works, but the result is unlikely to be useful until we move away from NSCalendarDate elsewhere
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];

    return [gregorianCalendar dateFromComponents: 
	    [gregorianCalendar components: NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate: alarmDate]];
}

- (int)daysFromToday;
{
    if (alarmType == PSAlarmInterval) [self _setDateFromInterval];
    
    return [[gregorianCalendar components: NSDayCalendarUnit fromDate: midnightOnDate([NSDate date]) toDate: alarmDate options: 0] day];
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
    return [dateFormatter stringFromDate: [self date]];
}

- (NSString *)shortDateString;
{
    return [shortDateFormatter stringFromDate: [self date]];
}

- (NSString *)timeString;
{
    return [timeFormatter stringFromDate: [self date]];
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
					[dateFormatter stringFromDate: date],
					[timeFormatter stringFromDate: date]];
        [date release];
        return nextDateTimeString;
    }
}

- (NSString *)intervalString;
{
    const unsigned long long mval = 999, minute = 60, hour = minute * 60, day = hour * 24, week = day * 7;
    unsigned long long interval = [self interval];
    if (interval == 0) return nil;

    if (interval == 1) return @"One second";
    if (interval == minute) return @"One minute";
    if (interval == hour) return @"One hour";
    if (interval == day) return @"One day";
    if (interval == week) return @"One week";

    if (interval % week == 0) return [NSString stringWithFormat: @"%u weeks", (unsigned)(interval / week)];
    if (interval % day == 0) return [NSString stringWithFormat: @"%u days", (unsigned)(interval / day)];
    if (interval % hour == 0) return [NSString stringWithFormat: @"%u hours", (unsigned)(interval / hour)];
    if (interval % minute == 0) return [NSString stringWithFormat: @"%u minutes", (unsigned)(interval / minute)];
    
    if (interval <= mval) return [NSString stringWithFormat: @"%u seconds", (unsigned)interval];
    if (interval <= mval * minute) return [NSString stringWithFormat: @"%u minutes", (unsigned)(interval / minute)];
    if (interval <= mval * hour) return [NSString stringWithFormat: @"%u hours", (unsigned)(interval / hour)];
    if (interval <= mval * day) return [NSString stringWithFormat: @"%u days", (unsigned)(interval / day)];
    return [NSString stringWithFormat: @"%u weeks", (unsigned)(interval / week)];

    return [self _stringForInterval: interval];
}

- (NSString *)repeatIntervalString;
{
    if (!repeating)
	return nil;
    
    NSString *intervalString = [self intervalString];
    if ([intervalString hasPrefix: @"One "])
	return [intervalString substringFromIndex: 4];
    
    return intervalString;
}

- (NSString *)timeRemainingString;
{
    NSString *timeRemainingString = [self _stringForInterval: ceil([self timeRemaining])];
    
    if (timeRemainingString == nil) return @"«expired»";
    return timeRemainingString;
}

- (NSAttributedString *)prettyDescription;
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSAttributedString *alertList = [alerts prettyList];

    [string appendAttributedString:
        [[NSString stringWithFormat: NSLocalizedString(@"At alarm time for '%@':\n", "Alert list title in pretty description, %@ replaced with message"), [self message]] small]];
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
}

- (void)resetTimer;
{
    if (timer != nil || alarmType != PSAlarmSet)
        return;

    alarmType = PSAlarmDate;
    if (![self isRepeating]) {
        [self setTimer];
    } else {
        // don't want to put this logic in setTimer or isValid because it can cause invalid alarms to be set (consider when someone clicks the "repeat" checkbox, then switches to a [nonrepeating, by design] date alarm, and enters a date that has passed: we do -not- want the alarm to magically morph into a repeating interval alarm)
        NSTimeInterval savedInterval = alarmInterval;
        if ([self setTimer]) {
	    // alarm is set, but not repeating - and the interval is wrong because it was computed from the date
	    alarmInterval = savedInterval;
	    [self setRepeating: YES];
	} else {
	    // alarm is now invalid: expired in the past, so we start the timer over again
	    // We could potentially start counting from the expiration date (or expiration date + n * interval), but this doesn't match our existing behavior.
            alarmType = PSAlarmInterval;
            [self setInterval: savedInterval];
            [self setTimer];
        }
    }
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
    return [NSString stringWithFormat: @"%@: type %@ date %@ interval %.1f%@%@",
        [super description], [self _alarmTypeString], alarmDate, alarmInterval,
        (repeating ? @" repeating" : @""),
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
        case PSAlarmSnooze:
        case PSAlarmInterval:
        case PSAlarmExpired:
            break;
        default:
            NSAssert1(NO, NSLocalizedString(@"Can't save alarm type %@", "Assertion for invalid PSAlarm type on string; %@ replaced with alarm type string"), [self _alarmTypeString]);
            break;
    }
    if ((alarmType != PSAlarmSet || repeating) && alarmType != PSAlarmDate) {
        [dict setObject: [NSNumber numberWithBool: repeating] forKey: PLAlarmRepeating];
        [dict setObject: [NSNumber numberWithDouble: alarmInterval] forKey: PLAlarmInterval];
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
                break;
            default:
                NSAssert1(NO, NSLocalizedString(@"Can't load alarm type %@", "Assertion for invalid PSAlarm type on load; %@ replaced with alarm type string"), [self _alarmTypeString]);
                break;
        }
        repeating = [[dict objectForKey: PLAlarmRepeating] boolValue];
        if ((alarmType != PSAlarmSet || repeating) && alarmType != PSAlarmDate)
            alarmInterval = [[dict objectForRequiredKey: PLAlarmInterval] doubleValue];
        snoozeInterval = [[dict objectForKey: PLAlarmSnoozeInterval] doubleValue];
        [self setMessage: [dict objectForRequiredKey: PLAlarmMessage]];
        alarmAlerts = [[PSAlerts alloc] initWithPropertyList: [dict objectForRequiredKey: PLAlarmAlerts]];
        [self setAlerts: alarmAlerts];
        [alarmAlerts release];
        [self resetTimer];
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
        if (alarmType == PSAlarmSet)
            alarmType = PSAlarmDate;
	// Note: the timer is not set here, so these alarms are inert.
	// This helps make importing atomic (see -[PSAlarms importVersion1Alarms])
    }
    return self;
}

@end
