//
//  NSAttributedString-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Mon Dec 16 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSAttributedString-NJRExtensions.h"

@implementation NSAttributedString (NJRExtensions)

- (float)heightWrappedToWidth:(float)width;
{
    float height = 0;
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString: self];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc]
        initWithContainerSize: NSMakeSize(width, MAXFLOAT)];
    [layoutManager addTextContainer: container];
    [storage addLayoutManager: layoutManager];
    (void) [layoutManager glyphRangeForTextContainer: container]; // force layout
    height = [layoutManager usedRectForTextContainer: container].size.height;
    [layoutManager release];
    [container release];
    [storage release];
    return height;
}

@end
