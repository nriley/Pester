//
//  NJRSplitView.m
//  Pester
//
//  Created by Nicholas Riley on Thu Feb 20 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRSplitView.h"


@implementation NJRSplitView

// inspiration (but very little code remaining) from <http://cocoa.mamasam.com/COCOADEV/2003/02/1/55911.php>
// XXX need to generalize: assumes the split is vertical, and you want to collapse a previous view
// XXX shouldn't set width to 0 as it can destroy layouts, but we have no other choice

- (void)collapseSubview:(NSView *)subview;
{
    NSSize size = [subview frame].size;
    NSAssert([self isVertical] && size.width > 1, @"unsupported configuration");
    expandedWidth = size.width;
    size.width = 0;
    [subview setFrameSize: size];
    [self setNeedsDisplay: YES];
}

// XXX this is a horrendous hack to work around NSSplitView bugs, and leaks memory
- (void)expandSubview:(NSView *)subview;
{
    NSArray *subviews = [self subviews];
    NSAssert([subviews count] == 2, @"unsupported configuration");
    NSBox *leftView = [subviews objectAtIndex: 0];
    NSView *rightView = [subviews objectAtIndex: 1];
    NSRect leftFrame = [leftView frame], rightFrame = [rightView frame];
    NSAssert([self isVertical] && subview == leftView, @"unsupported configuration");
    if (expandedWidth == 0) {
        expandedWidth = (rightFrame.size.width - [self dividerThickness]) / 2;
    }
    if ([[self delegate] respondsToSelector: @selector(splitView:constrainMaxCoordinate:ofSubviewAt:)]) {
        expandedWidth = [[self delegate] splitView: self constrainMaxCoordinate: expandedWidth ofSubviewAt: 0];
    }
    // begin hack
    NSBox *newLeftView = [[NSBox alloc] initWithFrame: leftFrame];
    [newLeftView setBorderType: [leftView borderType]];
    [newLeftView setTitlePosition: [leftView titlePosition]];
    [newLeftView setBoxType: [leftView boxType]];
    [newLeftView setAutoresizingMask: [leftView autoresizingMask]];
    [newLeftView setContentViewMargins: [leftView contentViewMargins]];
    NSView *leftContentView = [leftView contentView];
    [leftContentView retain];
    [leftContentView removeFromSuperviewWithoutNeedingDisplay];
    [newLeftView setContentView: leftContentView];
    [leftContentView release];
    leftFrame.origin = NSZeroPoint;
    rightFrame.origin.x += expandedWidth;
    leftFrame.size.width = expandedWidth;
    rightFrame.size.width -= expandedWidth;
    [leftView removeFromSuperviewWithoutNeedingDisplay];
    [rightView retain];
    [rightView removeFromSuperviewWithoutNeedingDisplay];
    [newLeftView setFrame: leftFrame];
    [rightView setFrame: rightFrame];
    [self addSubview: newLeftView];
    [self addSubview: rightView];
    [newLeftView release];
    [rightView release];
    // end hack
    [self setNeedsDisplay: YES];
}

- (void)mouseDown:(NSEvent *)event;
{
    if ([event clickCount] == 2) {
        NSPoint location = [self convertPoint: [event locationInWindow] fromView: nil];
        NSArray *subviews = [self subviews];
        NSView *leftView = [subviews objectAtIndex: 0];
        if (NSPointInRect(location, [leftView frame]) ||
            NSPointInRect(location, [[subviews objectAtIndex: 1] frame])) return;
        if ([self isSubviewCollapsed: leftView]) {
            [self expandSubview: leftView];
        } else {
            [self collapseSubview: leftView];
        }
    }
    [super mouseDown: event];
}

- (BOOL)isSubviewCollapsed:(NSView *)subview;
{
    NSRect frame = [subview frame];
    if (frame.origin.x == 1e6) return YES;
    if (frame.size.width <= 1) return YES;
    return NO;
}

@end
