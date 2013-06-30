//
//  NJRTableDelegate.m
//  Pester
//
//  Created by Nicholas Riley on Sun Oct 27 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRTableDelegate.h"
#import "NSTableView-NJRExtensions.h"

#pragma mark sorting support

typedef struct { NSString *key; BOOL descending; } SortContext;

// Sort array of itemNums, by looking up the itemNum in the dictionary of objects.
// based on code of Ondra Cada <ocs@ocs.cz> on cocoa-dev list

int ORDER_BY_CONTEXT(id left, id right, void *ctxt) {
    SortContext *context = (SortContext *)ctxt;
    int order = 0;
    id key = context->key;
    if (0 != key) {
        id first, second;	// the actual objects to compare

        if (context->descending) {
            first  = [right valueForKey: key];
            second = [left  valueForKey: key];
        } else {
            first  = [left  valueForKey: key];
            second = [right valueForKey: key];
        }

        if ([first respondsToSelector: @selector(caseInsensitiveCompare:)]) {
            order = [first caseInsensitiveCompare:second];
        } else { // sort numbers or dates
            order = [(NSNumber *)first compare:second];
        }
    }
    return order;
}

@interface NJRTableDelegate (Private)

- (void)_positionTypeSelectDisplay;
- (void)_sortByColumn:(NSTableColumn *)inTableColumn;

@end

@implementation NJRTableDelegate

#pragma mark initialize-release

- (void)awakeFromNib;
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_positionTypeSelectDisplay) name: NSViewFrameDidChangeNotification object: tableView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [sortingColumn release];
    [sortingKey release];
    [reorderedData release];
    [super dealloc];
}

#pragma mark accessing

- (void)setSortingColumn:(NSTableColumn *)inNewValue;
{
    [inNewValue retain];
    [sortingColumn release];
    sortingColumn = inNewValue;
}

- (void)setSortingKey:(NSString *)inNewValue;
{
    [inNewValue retain];
    [sortingKey release];
    sortingKey = inNewValue;
}

#pragma mark sorting

- (NSString *)_sortContextDefaultKey;
{
    NSString *autosaveName = [tableView autosaveName];
    if (autosaveName != nil)
        return [NSString stringWithFormat: @"NJRTableDelegate SortContext %@", autosaveName];
    else
        return nil;
}

- (void)_sortData;
{
    SortContext ctxt = { sortingKey, sortDescending };
    NSString *sortContextKey = [self _sortContextDefaultKey];

    if (sortContextKey != nil) {
        [[NSUserDefaults standardUserDefaults] setObject:
            [NSDictionary dictionaryWithObjectsAndKeys: sortingKey, @"sortingKey", [NSNumber numberWithBool: sortDescending], @"sortDescending", nil]
                                                    forKey: [self _sortContextDefaultKey]];
    }
    
    // sort the NSMutableArray
    [reorderedData sortUsingFunction: ORDER_BY_CONTEXT context: &ctxt];
    [tableView reloadData];
}

- (void)_sortByColumn:(NSTableColumn *)inTableColumn;
{
    NSSet *oldSelection = [self selectedItems];
    if (sortingColumn == inTableColumn) {
        // User clicked same column, change sort order
        sortDescending = !sortDescending;
        // Possible optimization: Don't actually re-sort if you just change the sorting direction; instead, just display either the nth item or the (count-1-n)th item depending on ascending/descending.)
    } else {
        // User clicked new column, change old/new column headers, save new sorting column, and re-sort the array.
        if (sortingColumn != nil) {
            [tableView setIndicatorImage: nil inTableColumn: sortingColumn];
            sortDescending = NO; // on initial sort, preserve previous sort order
        }
        [self setSortingKey: [inTableColumn identifier]];
        [self setSortingColumn: inTableColumn];
        [tableView setHighlightedTableColumn: inTableColumn];
    }
    [tableView setIndicatorImage: (sortDescending ? [NSImage imageNamed: @"NSDescendingSortIndicator"] : [NSImage imageNamed: @"NSAscendingSortIndicator"]) inTableColumn: inTableColumn];
    [self _positionTypeSelectDisplay];
    // Actually sort the data
    [self _sortData];
    [self selectItems: oldSelection];
}

- (void)_initialSortData;
{
    NSString *sortContextKey = [self _sortContextDefaultKey];
    NSDictionary *sortContext;
    NSString *key;
    NSTableColumn *column;

    if (sortContextKey == nil) goto noContext;
    if ( (sortContext = [[NSUserDefaults standardUserDefaults] dictionaryForKey: sortContextKey]) == nil) goto noContext;
    if ( (key = [sortContext objectForKey: @"sortingKey"]) == nil) goto noContext;
    if ( (column = [tableView tableColumnWithIdentifier: key]) == nil) goto noContext;
    sortDescending = [[sortContext objectForKey: @"sortDescending"] boolValue];
    [self _sortByColumn: column];
    return;
    
noContext:
    sortDescending = NO;
    [self _sortByColumn: [[tableView tableColumns] objectAtIndex: 0]];
}

- (NSMutableArray *)reorderedDataForData:(NSArray *)data;
{
    if (reorderedData == nil) {
        reorderedData = [data mutableCopy];
        [self _initialSortData];
    } else {
        NSSet *oldSelection = [self selectedItems];
        [reorderedData release]; reorderedData = nil;
        reorderedData = [data mutableCopy];
        [self _sortData];
        [self selectItems: oldSelection];
    }
    return reorderedData;
}

#pragma mark type selection

- (void)_positionTypeSelectDisplay;
{
    [tableView resetTypeSelect]; // avoid extraneous matching
    if ([tableView typeSelectDisplay] != nil && sortingColumn != nil) {
        NSControl *typeSelectControl = [tableView typeSelectDisplay];
        if ([typeSelectControl isKindOfClass: [NSControl class]]) {
            NSView *superview = [typeSelectControl superview];
            NSRect columnRect = [superview convertRect: [tableView rectOfColumn: [tableView columnWithIdentifier: sortingKey]] fromView: tableView];
            // XXX support horizontal scroll bar/clipping (not for Pester, but eventually)
            // NSRect tableScrollFrame = [[tableView enclosingScrollView] frame];
            NSRect selectFrame = [typeSelectControl frame];
            [superview setNeedsDisplayInRect: selectFrame]; // fix artifacts caused by moving view
            selectFrame.origin.x = columnRect.origin.x;
            selectFrame.size.width = columnRect.size.width;
            [typeSelectControl setAlignment: [[sortingColumn dataCell] alignment]];
            [typeSelectControl setFrame: selectFrame];
        }
    }
}

#pragma mark saving/restoring selection

- (NSSet *)selectedItems;
{
    NSMutableSet *result = [NSMutableSet set];
    NSIndexSet *selectedRowIndexes = [tableView selectedRowIndexes];
    unsigned rowIndex = [selectedRowIndexes firstIndex];

    while (rowIndex != NSNotFound) {
        id item = [reorderedData objectAtIndex: rowIndex];
        [result addObject: item];
	rowIndex = [selectedRowIndexes indexGreaterThanIndex: rowIndex];
    }
    return result;
}

- (void)selectItems:(NSSet *)inSelectedItems;
{
    NSEnumerator *e = [inSelectedItems objectEnumerator];
    NSMutableIndexSet *selectedRowIndexes = [[NSMutableIndexSet alloc] init];
    id item;
    
    [tableView deselectAll: nil];

    while ( (item = [e nextObject]) != nil) {
        unsigned row = [reorderedData indexOfObjectIdenticalTo: item];
        if (row == NSNotFound)
	    continue;
	
	[selectedRowIndexes addIndex: row];
    }
    
    [tableView selectRowIndexes: selectedRowIndexes byExtendingSelection: YES];
    [tableView scrollRowToVisible: [selectedRowIndexes lastIndex]];
    [selectedRowIndexes release];
}

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView *)aTableView didClickTableColumn:(NSTableColumn *)inTableColumn
{
    [[tableView window] makeFirstResponder: aTableView];
    [self _sortByColumn: inTableColumn];
}

- (void)tableViewColumnDidResize:(NSNotification *)notification;
{
    [self _positionTypeSelectDisplay];
}

- (void)tableViewColumnDidMove:(NSNotification *)notification;
{
    [self _positionTypeSelectDisplay];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc row:(int)rowIndex mouseLocation:(NSPoint)mouseLocation;
{
    id dataSource = [aTableView dataSource];
    
    if ([dataSource respondsToSelector: @selector(toolTipForRow:)])
	return [dataSource toolTipForRow: rowIndex];
    
    return nil;
}

#pragma mark NJRTableViewDelegate

- (void)tableView:(NSTableView *)aTableView selectRowMatchingString:(NSString *)matchString;
{
    // Look for a highlighted column, presuming we are sorted by that column, and search its values.
    NSTableColumn *col = [aTableView highlightedTableColumn];
    id dataSource = [aTableView dataSource];
    int i, rowCount = [reorderedData count];
    if (nil == col) return;
    if (sortDescending) {
        for ( i = rowCount - 1 ; i >= 0 ; i-- ) {
            NSComparisonResult order = [matchString caseInsensitiveCompare:
                [dataSource tableView: aTableView objectValueForTableColumn: col row: i]];
            if (order != NSOrderedDescending) break;
        }
        if (i < 0) i = 0;
    } else {
        for ( i = 0 ; i < rowCount ; i++ ) {
            NSComparisonResult order = [matchString caseInsensitiveCompare:
                [dataSource tableView: aTableView objectValueForTableColumn: col row: i]];
            if (order != NSOrderedDescending) break;
        }
        if (i >= rowCount) i = rowCount - 1;
    }
    // Now select row i -- either the one we found, or the first/last row if not found.
    [aTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: i] byExtendingSelection: NO];
    [aTableView scrollRowToVisible: i];
}

@end