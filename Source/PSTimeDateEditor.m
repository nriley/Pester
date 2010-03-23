//
//  PSTimeDateEditor.m
//  Pester
//
//  Created by Nicholas Riley on Sun Feb 16 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSTimeDateEditor.h"
#import "NJRDateFormatter.h"
#import "PSDateFieldEditor.h"

@implementation PSTimeDateEditor

+ (void)setUpTimeField:(NSTextField *)timeOfDay dateField:(NSTextField *)timeDate completions:(NSPopUpButton *)timeDateCompletions dateFieldEditor:(PSDateFieldEditor **)dateFieldEditor;
{
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

    [self updateTimeField: timeOfDay dateField: timeDate completions: timeDateCompletions dateFieldEditor: dateFieldEditor];
}

+ (void)updateTimeField:(NSTextField *)timeOfDay dateField:(NSTextField *)timeDate completions:(NSPopUpButton *)timeDateCompletions dateFieldEditor:(PSDateFieldEditor **)dateFieldEditor;
{
    NSTextField *editingField = nil;
    if ([timeOfDay currentEditor] != nil)
	editingField = timeOfDay;
    if ([timeDate currentEditor] != nil)
	editingField = timeDate;
    if (editingField != nil) {
	[editingField abortEditing];
	[editingField performSelector: @selector(becomeFirstResponder) withObject: nil afterDelay: 0];
    }

    if (dateFieldEditor != NULL) {
	[*dateFieldEditor release];
	*dateFieldEditor = nil;
    }

    // get English language completions (once)
    static NSArray *unlocalizedTitles = nil;
    if (unlocalizedTitles == nil)
	unlocalizedTitles = [[timeDateCompletions itemTitles] copy];
    [timeDateCompletions removeAllItems];

    if (![NJRDateFormatter naturalLanguageParsingAvailable])
	return;

    // get localized names
    NSArray *dayNames = [[timeDate formatter] weekdaySymbols];
    NSDictionary *localizedCompletions = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"DateCompletions" ofType: @"strings" inDirectory: nil forLocalization: [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode]]];

    // apply localization
    NSMenu *menu = [timeDateCompletions menu];
    NSEnumerator *e = [unlocalizedTitles objectEnumerator];
    NSString *title;
    while ( (title = [e nextObject]) != nil) {
	if ([title isEqualToString: @""]) {
	    [menu addItem: [NSMenuItem separatorItem]];
	    continue;
	}

	NSString *completion;
	if (localizedCompletions == nil)
	    completion = title;
	else if ( (completion = [localizedCompletions objectForKey: title]) == nil)
	    continue;

        NSRange matchingRange = [completion rangeOfString: @"«day»"];
        if (matchingRange.location != NSNotFound) {
            NSMutableString *format = [completion mutableCopy];
            [format deleteCharactersInRange: matchingRange];
            [format insertString: @"%@" atIndex: matchingRange.location];

	    NSEnumerator *we = [dayNames objectEnumerator];
            NSString *dayName;
	    while ( (dayName = [we nextObject]) != nil) {
                [timeDateCompletions addItemWithTitle: [NSString stringWithFormat: format, dayName]];
            }
	    [format release];
        } else {
	    [timeDateCompletions addItemWithTitle: completion];
	}
    }

    // set up completing field editor for date field
    NSArray *completions = [[timeDateCompletions itemTitles] arrayByAddingObjectsFromArray: dayNames];
    *dateFieldEditor = [[PSDateFieldEditor alloc] initWithCompletions: completions];
    [*dateFieldEditor setFieldEditor: YES];
    [*dateFieldEditor setDelegate: timeDate];

    if ([timeDateCompletions pullsDown]) // add a dummy first item, which gets consumed for the (obscured) title
	[timeDateCompletions insertItemWithTitle: @"" atIndex: 0];
}

@end
