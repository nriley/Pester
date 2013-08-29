//
//  NJRHotKeyFieldCell.m
//  Pester
//
//  Created by Nicholas Riley on Mon Mar 31 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRHotKeyFieldCell.h"
#import "NJRHotKeyField.h"

@implementation NJRHotKeyFieldCell

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength;
{
    [super selectWithFrame: aRect inView: controlView editor: textObj delegate: anObject start: 0 length: 0];
    [textObj setSelectable: NO];
    [textObj setEditable: NO];
}

@end
