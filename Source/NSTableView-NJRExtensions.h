//
//  NSTableView-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on Sun Oct 27 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NSTableView (NJRExtensions)

+ (NSImage *)ascendingSortIndicator;
+ (NSImage *)descendingSortIndicator;

- (float)cellHeight;

- (NSArray *)selectedRowIndices;

@end
