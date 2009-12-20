//
//  NJRTableView.m
//  Pester
//
//  Created by Nicholas Riley on Sun Nov 17 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRTableView.h"
#import "NSTableView-NJRExtensions.h"
#import "NSCharacterSet-NJRExtensions.h"

@interface NJRTableView (Private)
- (void)_resetTypeSelect;
@end

@implementation NJRTableView

#pragma mark type selection

- (id)typeSelectDisplay;
{
    return typeSelectDisplay;
}

- (void)moveToEndOfDocument:(id)sender {
    [self scrollRowToVisible: [self numberOfRows] - 1];
}

- (void)moveToBeginningOfDocument:(id)sender {
    [self scrollRowToVisible: 0];
}

- (void)keyDown:(NSEvent *)theEvent;
{
    NSString *characters;
    unichar firstCharacter;
    characters = [theEvent characters];
    firstCharacter = [characters characterAtIndex: 0];
    switch (firstCharacter) {
        case 0177: // delete key
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
            if ([self selectedRow] >= 0 && [[self dataSource] respondsToSelector: @selector(removeSelectedRowsFromTableView:)]) {
                [[self dataSource] removeSelectedRowsFromTableView: self];
            }
            return;
        case NSHomeFunctionKey:
            [self moveToBeginningOfDocument: nil];
            return;
        case NSEndFunctionKey:
            [self moveToEndOfDocument: nil];
            return;
    }
    if ([[NSCharacterSet typeSelectSet] characterIsMember: firstCharacter]) {
        // invoking -[NSResponder interpretKeyEvents:] will cause insertText: to be invoked, and allows function keys to still work.
        [self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
    } else {
        [super keyDown: theEvent];
    }
}

- (void)insertText:(id)inString;
{
    // For consistency with List Manager as documented, reset the typeahead buffer after twice the delay until key repeat (in ticks).
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int keyRepeatTicks = [defaults integerForKey: @"InitialKeyRepeat"];
    NSTimeInterval resetDelay;

    if (keyRepeatTicks == 0) keyRepeatTicks = 35; // default may be missing; if so, set default

    resetDelay = MIN(2.0 / 60.0 * keyRepeatTicks, 2.0);

    if (typed == nil) typed = [[NSMutableString alloc] init];
    [typed appendString: inString];

    // Cancel any previously queued future invocations of _resetTypeSelect
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(_resetTypeSelect) object: nil];

    // queue an invocation of clearAccumulatingTypeahead for the near future.
    [self performSelector: @selector(_resetTypeSelect) withObject: nil afterDelay: resetDelay];

    // Use stringWithString to make an autoreleased copy, since we may clear out the original string below before it can be used.
    [[self delegate] tableView: self selectRowMatchingString: [NSString stringWithString: typed]];

    // Show the current typeahead string in the optional display field, like CodeWarrior does (well, not really, CW is much more elegant because it doesn't select anything until you stop typing)
    [typeSelectDisplay setObjectValue: typed];
}

- (void)_resetTypeSelect;
{
    [typed setString: @""];
    [typeSelectDisplay setObjectValue: nil];
}

- (void)resetTypeSelect;
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(_resetTypeSelect) object: nil];
    [self _resetTypeSelect];
}

@end
