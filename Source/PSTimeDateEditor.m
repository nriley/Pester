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

@interface NSObject (PSTimeDateController)
- (IBAction)update:(id)sender;
@end

@implementation PSTimeDateEditor

// XXX instantiate from IB (use outlets rather than many-argument constructor); eliminate redundancy between PSAlarmSetController and PSSnoozeUntilController (e.g. popup calendar)

- (id)initWithTimeField:(NSTextField *)timeField dateField:(NSTextField *)dateField completions:(NSPopUpButton *)completions controller:(id)obj;
{
    if ( (self = [super init]) != nil) {
	timeOfDay = timeField;
	timeDate = dateField;
	timeDateCompletions = completions;
	controller = obj;

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

        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(naturalLanguageDateParsingDidChange:) name: NJRDateFormatterNaturalLanguageDateParsingDidChangeNotification object: nil];

	[self _update];
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [dateFieldEditor release];
    [super dealloc];
}

- (PSDateFieldEditor *)dateFieldEditor;
{
    return dateFieldEditor;
}

- (void)_update;
{
    NSTextField *editingField = nil;
    NSText *editor;
    if ( (editor = [timeOfDay currentEditor]) != nil)
	editingField = timeOfDay;
    else if ( (editor = [timeDate currentEditor]) != nil)
	editingField = timeDate;
    if (editingField != nil) {
        NSString *editingString = editor.string;
        NSRange editingSelectedRange = editor.selectedRange;
        [editingField.window disableFlushWindow];
        dispatch_async(dispatch_get_main_queue(), ^{
            [editingField becomeFirstResponder];
            NSText *editor = [editingField currentEditor];
            editor.string = editingString;
            editor.selectedRange = editingSelectedRange;
            [editingField.window enableFlushWindow];
        });
        [editingField abortEditing];
    }

    [dateFieldEditor release];
    dateFieldEditor = nil;

    // get English language completions (once)
    static NSArray *unlocalizedTitles = nil;
    if (unlocalizedTitles == nil)
	unlocalizedTitles = [[timeDateCompletions itemTitles] copy];
    [timeDateCompletions removeAllItems];

    if (![NJRDateFormatter naturalLanguageParsingAvailable]) {
        [timeDateCompletions setEnabled: NO];
	return;
    }

    // get localized names
    NSArray *dayNames = [[timeDate formatter] weekdaySymbols];
    NSDictionary *localizedCompletions = [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"DateCompletions" ofType: @"strings" inDirectory: nil forLocalization: [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode]]];

    // apply localization
    NSArray *completions;
    if (localizedCompletions == nil) {
	// if we've got nothing else, just use the day names
	[timeDateCompletions addItemsWithTitles: dayNames];
	completions = dayNames;
    } else {
	NSMenu *menu = [timeDateCompletions menu];
	NSEnumerator *e = [unlocalizedTitles objectEnumerator];
	NSString *title;
	while ( (title = [e nextObject]) != nil) {
	    if ([title isEqualToString: @""]) {
		[menu addItem: [NSMenuItem separatorItem]];
		continue;
	    }

	    NSString *completion;
	    if ( (completion = [localizedCompletions objectForKey: title]) == nil)
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
	completions = [[timeDateCompletions itemTitles] arrayByAddingObjectsFromArray: dayNames];
    }

    // set up completing field editor for date field
    dateFieldEditor = [[PSDateFieldEditor alloc] initWithCompletions: completions];
    [dateFieldEditor setFieldEditor: YES];
    [dateFieldEditor setDelegate: (id <NSTextViewDelegate>)timeDate];

    [timeDateCompletions setEnabled: [timeDate isEnabled] && [timeDateCompletions numberOfItems] > 0];

    if ([timeDateCompletions pullsDown]) // add a dummy first item, which gets consumed for the (obscured) title
	[timeDateCompletions insertItemWithTitle: @"" atIndex: 0];
}

- (void)naturalLanguageDateParsingDidChange:(NSNotification *)notification;
{
    [self _update];
    [controller update: nil];
}

@end
