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

/* only defined in 10.2, but we want to be able to compile without warnings on 10.1.x */
@interface NSColor (JaguarExtras)
+ (NSColor *)alternateSelectedControlColor;
@end

@implementation NJRTableView

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    if ( (self = [super initWithCoder: aDecoder]) != nil) {
        toolTipRegionList = [[NSMutableDictionary alloc] initWithCapacity: 20];
    }
    return self;
}

- (void)dealloc;
{
    [toolTipRegionList release];
    [super dealloc];
}

#pragma mark tool tips

- (void)reloadData;
{
    [toolTipRegionList removeAllObjects];
    [self removeAllToolTips];
    [super reloadData];
}

- (void)noteNumberOfRowsChanged;
{
    [toolTipRegionList removeAllObjects];
    [self removeAllToolTips];
    [super noteNumberOfRowsChanged];
}

- (NSString *)_keyForColumn:(int)columnIndex row:(int)rowIndex;
{
    return [NSString stringWithFormat:@"%d,%d", rowIndex, columnIndex];
}

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data;
{
    // ask our data source for the tool tip
    if ([[self dataSource] respondsToSelector: @selector(tableView:toolTipForTableColumn:row:)]) {
        if ([self rowAtPoint: point] >= 0) return [[self dataSource] tableView: self toolTipForTableColumn: [[self tableColumns] objectAtIndex: [self columnAtPoint: point]] row: [self rowAtPoint: point]];
    }
    return nil;
}

- (NSRect)frameOfCellAtColumn:(int)columnIndex row:(int)rowIndex;
{
    // this cell is apparently displayed, so we need to add a region for it
    NSNumber *toolTipTag;
    NSRect result = [super frameOfCellAtColumn: columnIndex row: rowIndex];
    // check if cell is already in the list
    NSString *cellKey = [self _keyForColumn: columnIndex row: rowIndex];
    // remove old region
    if (toolTipTag = [toolTipRegionList objectForKey: cellKey])
        [self removeToolTip: [toolTipTag intValue]];
    // add new region
    [toolTipRegionList setObject: [NSNumber numberWithInt: [self addToolTipRect: result owner: self userData: cellKey]] forKey: cellKey];
    return [super frameOfCellAtColumn: columnIndex row: rowIndex];
}

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
    if (![[self delegate] respondsToSelector:@selector(selectString:inTableView:)]) {
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

#pragma mark row coloring

- (void)drawGridInClipRect:(NSRect)rect;
{
    NSRange columnRange = [self columnsInRect: rect];
    int i;
    // match iTunes’ grid color
    [[[NSColor gridColor] blendedColorWithFraction: 0.70 ofColor: [NSColor whiteColor]] set];
    for (i = columnRange.location ; i < NSMaxRange(columnRange) ; i++) {
        NSRect colRect = [self rectOfColumn:i];
        int rightEdge = (int) 0.5 + colRect.origin.x + colRect.size.width;
        [NSBezierPath strokeLineFromPoint: NSMakePoint(-0.5 + rightEdge, -0.5 + rect.origin.y)
                                  toPoint: NSMakePoint(-0.5 + rightEdge, -0.5 + rect.origin.y + rect.size.height)];
    }
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect;
{
    NSColor *evenColor, *oddColor = [self backgroundColor];
    float cellHeight = [self cellHeight];
    NSRect visibleRect = [self visibleRect];
    NSRect highlightRect;
    
    if ([NSColor respondsToSelector: @selector(alternateSelectedControlColor)])
        evenColor = [[NSColor alternateSelectedControlColor] highlightWithLevel:0.90];
    else // match iTunes’ row background color
        evenColor = [NSColor colorWithCalibratedRed: 0.929 green: 0.953 blue: 0.996 alpha:1.0];

    highlightRect.origin = NSMakePoint(NSMinX(visibleRect), (int)(NSMinY(clipRect) / cellHeight) * cellHeight);
    highlightRect.size = NSMakeSize(NSWidth(visibleRect), cellHeight);

    while (NSMinY(highlightRect) < NSMaxY(clipRect)) {
        NSRect clippedHighlightRect = NSIntersectionRect(highlightRect, clipRect);
        int row = (int)((NSMinY(highlightRect) + cellHeight / 2.0) / cellHeight);
        NSColor *rowColor = (row % 2 == 0) ? evenColor : oddColor;
        [rowColor set];
        NSRectFill(clippedHighlightRect);
        highlightRect.origin.y += cellHeight;
    }

    [super highlightSelectionInClipRect: clipRect];
}

@end
