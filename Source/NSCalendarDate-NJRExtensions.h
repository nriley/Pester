//
//  NSCalendarDate-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on Sun Dec 22 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSCalendarDate (NJRExtensions)

+ (NSCalendarDate *)dateForDay:(NSDate *)date;
+ (NSCalendarDate *)dateWithDate:(NSDate *)date atTime:(NSDate *)time;

@end
