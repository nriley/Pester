//
//  NSTableView-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sun Oct 27 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSTableView-NJRExtensions.h"


@interface NSTableView (PumaPrivate)
// Declarations of 10.1 private methods, just to make the compiler happy.
+ (id) _defaultTableHeaderReverseSortImage;
+ (id) _defaultTableHeaderSortImage;
@end

@implementation NSTableView (NJRExtensions)

+ (NSImage *)ascendingSortIndicator;
{
    NSImage *result = [NSImage imageNamed: @"NSAscendingSortIndicator"];
    if (result == nil && [[NSTableView class] respondsToSelector: @selector(_defaultTableHeaderSortImage)])
        result = [NSTableView _defaultTableHeaderSortImage];
    return result;
}

+ (NSImage *)descendingSortIndicator;
{
    NSImage *result = [NSImage imageNamed:@"NSDescendingSortIndicator"];
    if (result == nil && [[NSTableView class] respondsToSelector:@selector(_defaultTableHeaderReverseSortImage)])
        result = [NSTableView _defaultTableHeaderReverseSortImage];
    return result;
}

- (NSArray *)selectedRowIndices;
{
    NSEnumerator *theEnum = [self selectedRowEnumerator];
    NSNumber *rowNumber;
    NSMutableArray *rowNumberArray = [NSMutableArray arrayWithCapacity: [self numberOfSelectedRows]];

    while (nil != (rowNumber = [theEnum nextObject]) )
        [rowNumberArray addObject: rowNumber];

    return rowNumberArray;
}

- (float)cellHeight;
{
    return [self rowHeight] + [self intercellSpacing].height;
}

// causes NSTableView to get keyboard focus (with thanks to Pierre-Olivier Latour)
- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

@end
