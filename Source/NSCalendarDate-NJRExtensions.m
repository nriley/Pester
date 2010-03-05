//
//  NSCalendarDate-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sun Dec 22 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSCalendarDate-NJRExtensions.h"


@interface NSCalendarDate (Private)

// implemented in Foundation, but not declared in NSDate.h
+ (NSCalendarDate *)dateWithDate:(NSDate *)date;

@end

@implementation NSCalendarDate (NJRExtensions)

+ (NSCalendarDate *)dateForDay:(NSDate *)date;
{
    if (date == nil) return nil;
    NSCalendarDate *calDate = [NSCalendarDate dateWithDate: date];
    return [NSCalendarDate dateWithYear: [calDate yearOfCommonEra]
                                  month: [calDate monthOfYear]
                                    day: [calDate dayOfMonth]
                                   hour: 0
                                 minute: 0
                                 second: 0
                               timeZone: nil];
}

+ (NSCalendarDate *)dateWithDate:(NSDate *)aDate atTime:(NSDate *)aTime;
{
    NSCalendarDate *calTime, *calDate;
    if (aTime == nil || aDate == nil) return nil;
    calTime = [NSCalendarDate dateWithDate: aTime];
    calDate = [NSCalendarDate dateWithDate: aDate];
    if (calTime == nil || calDate == nil) return nil;
    return [NSCalendarDate dateWithYear: [calDate yearOfCommonEra]
                                  month: [calDate monthOfYear]
                                    day: [calDate dayOfMonth]
                                   hour: [calTime hourOfDay]
                                 minute: [calTime minuteOfHour]
                                 second: [calTime secondOfMinute]
                               timeZone: nil];
}

@end
