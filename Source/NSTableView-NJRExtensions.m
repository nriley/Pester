//
//  NSTableView-NJRExtensions.m
//  HostLauncher
//
//  Created by Nicholas Riley on Mon Apr 22 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSTableView-NJRExtensions.h"


@implementation NSTableView (NJRExtensions)

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
