//
//  NJRScrollView.m
//  HostLauncher
//
//  Created by nicholas on Tue Oct 30 2001.
//  Copyright (c) 2001 Nicholas Riley. All rights reserved.
//

#import "NJRScrollView.h"


@implementation NJRScrollView

- (BOOL)needsDisplay;
{
    NSResponder *resp = nil;
    if ([[self window] isKeyWindow]) {
        resp = [[self window] firstResponder];
        if (resp == lastResp) return [super needsDisplay];
    } else if (lastResp == nil) {
        return [super needsDisplay];
    }
    shouldDrawFocusRing = (resp != nil && [resp isKindOfClass: [NSView class]] &&
                           [(NSView *)resp isDescendantOf: self]); // [sic]
    lastResp = resp;
    [self setKeyboardFocusRingNeedsDisplayInRect: [self bounds]];
    return YES;
}

- (void)drawRect:(NSRect)rect {
    [super drawRect: rect];
    if (shouldDrawFocusRing) {
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRectFill([self bounds]);
    }
}

@end