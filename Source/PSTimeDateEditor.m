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
    [[NJRDateFormatter alloc] init]; // XXX testing
    [NSDateFormatter setDefaultFormatterBehavior: NSDateFormatterBehavior10_4];
    static NSDateFormatter *timeFormatter = nil, *dateFormatter = nil;
    if (timeFormatter == nil) {
        timeFormatter = [[NJRDateFormatter timeFormatter] retain];
	[timeFormatter setLenient: YES];
	[timeFormatter setDateStyle: NSDateFormatterNoStyle];
	[timeFormatter setTimeStyle: NSDateFormatterShortStyle];
	dateFormatter = [[NJRDateFormatter dateFormatter] retain];
	[dateFormatter setLenient: YES];
	[dateFormatter setDateStyle: NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    }
    [timeOfDay setFormatter: timeFormatter];
    [timeDate setFormatter: dateFormatter];
    [timeDate setObjectValue: [NSDate date]];

    // add completions
    NSArray *dayNames = [dateFormatter weekdaySymbols];
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
	    [format release];
        } else itemIndex++;
    }
    if ([timeDateCompletions pullsDown]) // add a dummy first item, which gets consumed for the (obscured) title
	[timeDateCompletions insertItemWithTitle: @"" atIndex: 0];
}

@end
