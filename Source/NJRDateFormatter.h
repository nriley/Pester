//
//  NJRDateFormatter.h
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NJRDateFormatter : NSDateFormatter {
    NSDictionary *alteredLocale;
}

+ (NSString *)format:(NSString *)format withoutComponent:(unichar)component;
+ (NSString *)localizedDateFormatIncludingWeekday:(BOOL)weekday;
+ (NSString *)localizedShortDateFormatIncludingWeekday:(BOOL)weekday;
+ (NSString *)localizedTimeFormatIncludingSeconds:(BOOL)seconds;

@end
