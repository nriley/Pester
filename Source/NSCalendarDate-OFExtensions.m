// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSCalendarDate-OFExtensions.h"

#import <Foundation/Foundation.h>

// RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSCalendarDate-OFExtensions.m,v 1.15 2002/03/09 01:54:02 kc Exp $")

@implementation NSCalendarDate (OFExtensions)

+ (NSCalendarDate *)unixReferenceDate;
{
    static NSCalendarDate *unixReferenceDate = nil;
    const long zero = 0;

    if (unixReferenceDate == nil) {
        unixReferenceDate = [[NSCalendarDate dateWithString:[NSString stringWithCString:ctime(&zero)] calendarFormat:@"%a %b %d %H:%M:%S %Y\n"] retain];
    }
    return unixReferenceDate;
}

- (void)setToUnixDateFormat;
{
    if ([self yearOfCommonEra] == [(NSCalendarDate *)[NSCalendarDate date] yearOfCommonEra])
	[self setCalendarFormat:@"%b %d %H:%M"];
    else
	[self setCalendarFormat:@"%b %d %Y"];
}

// We're going with Noon instead of midnight, since it's a bit more tolerant of
// time zone switching. (When you're adding days.)

- (NSCalendarDate *)safeReferenceDate;
{
    int year, month, day;

    year = [self yearOfCommonEra];
    month = [self monthOfYear];
    day = [self dayOfMonth];

    return [NSCalendarDate dateWithYear:year month:month day:day
                           hour:12 minute:0 second:0 timeZone:[NSTimeZone localTimeZone]];
}

- (NSCalendarDate *)firstDayOfMonth;
{
    NSCalendarDate *firstDay;

    firstDay = [[NSCalendarDate alloc] initWithYear:[self yearOfCommonEra]
        month:[self monthOfYear]
        day:1
        hour:12
        minute:0
        second:0
        timeZone:nil];
    return [firstDay autorelease];
}

- (NSCalendarDate *)lastDayOfMonth;
{
    return [[self firstDayOfMonth] dateByAddingYears:0 months:1 days:-1 hours:0 minutes:0 seconds:0];
}

- (int)numberOfDaysInMonth;
{
    return [[self lastDayOfMonth] dayOfMonth];
}

- (int)weekOfMonth;
{
    // Returns 1 through 6. Weeks are Sunday-Saturday.
    int dayOfMonth;
    int firstWeekDayOfMonth;
    
    dayOfMonth = [self dayOfMonth];
    firstWeekDayOfMonth = [[self firstDayOfMonth] dayOfWeek];
    return (dayOfMonth - 1 + firstWeekDayOfMonth) / 7 + 1;
}

- (BOOL)isInSameWeekAsDate:(NSCalendarDate *)otherDate;
{
    int weekOfMonth;

    // First, do a quick check to filter out dates which are more than a week away.
    if (abs([self dayOfCommonEra] - [otherDate dayOfCommonEra]) > 6)
        return NO;

    // Then, handle the simple case, when both dates are the same year and month.
    if ([self yearOfCommonEra] == [otherDate yearOfCommonEra] && [self monthOfYear] == [otherDate monthOfYear])
        return ([self weekOfMonth] == [otherDate weekOfMonth]);

    // Now we know the other date is within a week of us, and not in the same month. 
    weekOfMonth = [self weekOfMonth];
    if (weekOfMonth == 1) {
        // We are in the first week of the month. The otherDate is in the same week if its weekday is earlier than ours.
        return ([otherDate dayOfWeek] < [self dayOfWeek]);
    } else if (weekOfMonth == [[self lastDayOfMonth] weekOfMonth]) {
        // We are in the last week of the month. The otherDate is in the same week if its weekday is later than ours.
        return ([otherDate dayOfWeek] > [self dayOfWeek]);
    } else {
        // We are somewhere in the middle of the month, so the otherDate cannot be in the same week.
        return NO;
    }
}

@end
