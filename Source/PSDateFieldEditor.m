//
//  PSDateFieldEditor.m
//  Pester
//
//  Created by Nicholas Riley on 3/1/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "PSDateFieldEditor.h"


@implementation PSDateFieldEditor

- (id)initWithCompletions:(NSArray *)dateCompletions;
{
    if ( (self = [super init]) == nil)
	return nil;
    
    allCompletions = [dateCompletions copy];
    
    return self;
}

- (void)dealloc;
{
    [allCompletions release];
    [super dealloc];
}

- (void)insertText:(id)insertString;
{
    [super insertText: insertString];
    [self complete: nil];
}

- (void)moveDown:(id)sender;
{
    [self deleteToEndOfLine: sender];
    [self complete: sender];
}

@end

@implementation PSDateFieldEditor (NSCompletion)

- (NSRange)rangeForUserCompletion;
{
    NSRange range = [super rangeForUserCompletion];
    range.length += range.location;
    range.location = 0;
    
    return range;
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int *)idx;
{
    NSString *partialMatch = [self string];
    NSUInteger partialLength = [partialMatch length];
    NSMutableArray *completions = [allCompletions mutableCopy];
    for (int i = [completions count] - 1 ; i >= 0 ; i--) {
	NSString *completion = [completions objectAtIndex: i];
	unsigned length = [completion length];
	if (partialLength == 0) {
	    if (length > 0)
		continue;
	} else if (length >= partialLength &&
		   [partialMatch compare:
		    [completion substringToIndex: partialLength] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
	   continue;
        }
	
	[completions removeObjectAtIndex: i];
    }
    return [completions autorelease];
}

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag;
{
    // space bar (or right arrow, which is less ideal)
    if (movement == NSRightTextMovement)
	flag = NO;
	
    if (!flag)
	[self deleteToEndOfLine: nil];

    [super insertCompletion: word forPartialWordRange: charRange movement: movement isFinal: flag];

    if (movement == NSTabTextMovement)
	[self insertTab: nil];
}

@end
