//
//  NJRTableDelegate.m
//  Pester
//
//  Created by Nicholas Riley on Sun Oct 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NJRTableDelegate.h"
#import "NSTableView-NJRExtensions.h"

#pragma mark sorting support

typedef struct { NSString *key; BOOL descending; } SortContext;

// Sort array of itemNums, by looking up the itemNum in the dictionary of dictionaries.
// based on code of Ondra Cada <ocs@ocs.cz> on cocoa-dev list

int ORDER_BY_CONTEXT(id left, id right, void *ctxt) {
    SortContext *context = (SortContext *)ctxt;
    int order = 0;
    id key = context->key;
    if (0 != key) {
        id first, second;	// the actual objects to compare

        if (context->descending) {
            first  = [right objectForKey: key];
            second = [left  objectForKey: key];
        } else {
            first  = [left  objectForKey: key];
            second = [right objectForKey: key];
        }

        if ([first respondsToSelector: @selector(caseInsensitiveCompare:)]) {
            order = [first caseInsensitiveCompare:second];
        } else { // sort numbers or dates
            order = [(NSNumber *)first compare:second];
        }
    }
    return order;
}

@implementation NJRTableDelegate

#pragma mark initialize-release

- (void)dealloc
{
    [sortingColumn release];
    [sortingKey release];
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

#pragma mark saving/restoring selection

- (NSSet *)selectedItems;
{
    NSMutableSet *result = [NSMutableSet set];
    NSEnumerator *e = [tableView selectedRowEnumerator];
    NSNumber *rowNum;

    while ( (rowNum = [e nextObject]) != nil) {
        id item = [oData objectAtIndex: [rowNum intValue]];
        [result addObject: item];
    }
    return result;
}

- (void)selectItems:(NSSet *)inSelectedItems;
{
    NSEnumerator *e = [inSelectedItems objectEnumerator];
    id item;
    int savedLastRow = 0;

    [tableView deselectAll: nil];

    while ( (item = [e nextObject]) != nil ) {
        int row = [oData indexOfObjectIdenticalTo: item];
        if (row != NSNotFound) {
            [tableView selectRow: row byExtendingSelection: YES];
            savedLastRow = row;
        }
    }
    [tableView scrollRowToVisible: savedLastRow];
}

// ----------------------------------------------------------------------------------------
// Sorting
// ----------------------------------------------------------------------------------------

- (void)sortData
{
    SortContext ctxt = { sortingKey, sortDescending };
    NSSet *oldSelection = [self selectedItems];

    // sort the NSMutableArray
    [oData sortUsingFunction: ORDER_BY_CONTEXT context: &ctxt];

    [tableView reloadData];
    [self selectItems: oldSelection];
}

- (void)sortByColumn:(NSTableColumn *)inTableColumn;
{
    if (sortingColumn == inTableColumn) {
        // User clicked same column, change sort order
        sortDescending = !sortDescending;
        // Possible optimization: Don't actually re-sort if you just change the sorting direction;
        // instead, just display either the nth item or the (count-1-n)th item depending on ascending/descending.)
    } else {
        // User clicked new column, change old/new column headers,
        // save new sorting column, and re-sort the array.
        sortDescending = NO;
        if (nil != sortingColumn) {
            [tableView setIndicatorImage: nil inTableColumn: sortingColumn];
        }
        [self setSortingKey: [inTableColumn identifier]];
        [self setSortingColumn: inTableColumn];
        [tableView setHighlightedTableColumn: inTableColumn];
    }
    [tableView setIndicatorImage: (sortDescending ? [NSTableView descendingSortIndicator] : [NSTableView ascendingSortIndicator]) inTableColumn: inTableColumn];
    // Actually sort the data
    [self sortData];
}

//	Sort by whatever column was clicked upon
- (void)tableView:(NSTableView*)aTableView didClickTableColumn:(NSTableColumn *)inTableColumn
{
    [[tableView window] makeFirstResponder: aTableView]; // help make this tableView be first responder
    [self sortByColumn:inTableColumn];
}

// ----------------------------------------------------------------------------------------
// Alphabetic Type Ahead
// ----------------------------------------------------------------------------------------

- (void) typeAheadString:(NSString *)inString;
{
    // This general sample looks for a highlighted column, presuming that is that column we are sorted by, and uses that as the lookup key.
    NSTableColumn *col = [tableView highlightedTableColumn];
    if (nil != col) {
        NSString *key = [col identifier];
        int i;
        for ( i = 0 ; i < [oData count] ; i++ ) {
            NSDictionary *rowDict = [oData objectAtIndex:i];
            NSString *compareTo = [rowDict objectForKey:key];
            NSComparisonResult order = [inString caseInsensitiveCompare:compareTo];
            if (order != NSOrderedDescending) break;
        }
        // Make sure we're not overflowing the row count.
        if (i >= [oData count]) {
            i = [oData count] - 1;
        }
        // Now select row i -- either the one we found, or the last row if not found.
        [tableView selectRow:i byExtendingSelection:NO];
        [tableView scrollRowToVisible:i];
    }
}

@end
