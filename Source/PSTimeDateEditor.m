//
//  PSTimeDateEditor.m
//  Pester
//
//  Created by Nicholas Riley on Sun Feb 16 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSTimeDateEditor.h"
#import "NJRDateFormatter.h"

@implementation PSTimeDateEditor

+ (void)setUpTimeField:(NSTextField *)timeOfDay dateField:(NSTextField *)timeDate completions:(NSPopUpButton *)timeDateCompletions;
{
    static NJRDateFormatter *timeFormatter = nil, *dateFormatter = nil;
    if (timeFormatter == nil) {
        timeFormatter = [[NJRDateFormatter alloc] initWithDateFormat: [NJRDateFormatter localizedTimeFormatIncludingSeconds: NO] allowNaturalLanguage: YES];
        dateFormatter = [[NJRDateFormatter alloc] initWithDateFormat: [NJRDateFormatter localizedDateFormatIncludingWeekday: NO] allowNaturalLanguage: YES];
    }
    [timeOfDay setFormatter: timeFormatter];
    [timeDate setFormatter: dateFormatter];
    [timeDate setObjectValue: [NSDate date]];

    // add completions
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *dayNames = [defaults arrayForKey: NSWeekDayNameArray];
    NSArray *completions = [timeDateCompletions itemTitles];
    NSEnumerator *e = [completions objectEnumerator];
    NSString *title;
    int itemIndex = 0;
    NSRange matchingRange;
    while ( (title = [e nextObject]) != nil) {
        matchingRange = [title rangeOfString: @"«day»"];
        if (matchingRange.location != NSNotFound) {
            NSMutableString *format = [title mutableCopy];
            NSEnumerator *we = [dayNames objectEnumerator];
            NSString *dayName;
            [format deleteCharactersInRange: matchingRange];
            [format insertString: @"%@" atIndex: matchingRange.location];
            [timeDateCompletions removeItemAtIndex: itemIndex];
            while ( (dayName = [we nextObject]) != nil) {
                [timeDateCompletions insertItemWithTitle: [NSString stringWithFormat: format, dayName] atIndex: itemIndex];
                itemIndex++;
            }
        } else itemIndex++;
    }
}

@end
