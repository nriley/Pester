//
//  NJRMenuSlider.m
//
//  Created by Nicholas Riley on 12/6/09.
//  Copyright 2009 Nicholas Riley. All rights reserved.
//

#import "NJRMenuSlider.h"

// modeled after AppleVolumeItemView in SystemUIServer (but much simpler)
@implementation NJRMenuSlider

- (void)viewDidMoveToWindow;
{
    [super viewDidMoveToWindow];
    [[self window] makeFirstResponder: self];
}

- (void)keyDown:(NSEvent *)theEvent;
{
    double value;
    
    // XXX is there a way to call rather than emulate the standard behavior?
    switch ([[theEvent charactersIgnoringModifiers] characterAtIndex: 0]) {
	case NSUpArrowFunctionKey:
	    value = MIN([self doubleValue] + ([self maxValue] - [self minValue]) / 10, [self maxValue]);
	    break;
	case NSDownArrowFunctionKey:
	    value = MAX([self doubleValue] - ([self maxValue] - [self minValue]) / 10, [self minValue]);
	    break;
	case NSPageUpFunctionKey:
	    value = [self maxValue];
	    break;
	case NSPageDownFunctionKey:
	    value = [self minValue];
	    break;
	default:
	    [super keyDown: theEvent];
	    return;
    }

    [self setDoubleValue: value];
    [self sendAction: [self action] to: [self target]];
}

@end
