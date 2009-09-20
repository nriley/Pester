//
//  PSVolumeController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSVolumeController.h"
#import "NJRSoundManager.h"
#import "NJRNonCenteringWindow.h"

@implementation PSVolumeController

+ (PSVolumeController *)controllerWithVolume:(float)volume delegate:(id)aDelegate;
{
    return [[self alloc] initWithVolume: volume delegate: aDelegate];
}

- (id)initWithVolume:(float)volume delegate:(id)aDelegate;
{
    if ( (self = [self initWithWindowNibName: @"Volume"]) != nil) {
        [self window]; // connect outlets
        NSWindow *window = [[NJRNonCenteringWindow alloc] initWithContentRect: [contentView bounds] styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];

        if ([NJRSoundManager volumeIsNotMutedOrInvalid: volume])
            [volumeSlider setFloatValue: volume];

        delegate = [aDelegate retain];

        [window setContentView: contentView];
	[window setInitialFirstResponder: volumeSlider];
	[window makeFirstResponder: volumeSlider];
        [window setOpaque: NO];
        [window setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.81f alpha: 0.9f]];
        [window setHasShadow: YES];
        [window setOneShot: YES];
        [window setDelegate: self];
        NSView *view = [aDelegate volumeControllerLaunchingView: self];
        if (view != nil) {
            NSRect rect = [view convertRect: [view bounds] toView: nil];
            NSWindow *parentWindow = [view window];
            rect.origin = [parentWindow convertBaseToScreen: rect.origin];
            rect.origin.x -= [window frame].size.width - rect.size.width + 1;
            [window setFrameTopLeftPoint: rect.origin];
            NSRect visibleFrame = [[parentWindow screen] visibleFrame];
            if (!NSContainsRect(visibleFrame, [window frame])) {
                NSPoint viewTopLeft = { rect.origin.x, rect.origin.y + rect.size.height };
                [window setFrameOrigin: viewTopLeft];
            }
        }

        // -[NSApplication beginModalSessionForWindow:] shows and centers the window; we use NJRNonCenteringWindow to prevent the repositioning from succeeding
        NSModalSession session = [NSApp beginModalSessionForWindow: window];
	// In 10.6, we can no longer force the modal session to work by "seeding" the slider with a mouse-down event.
	// Instead, we stop the modal session on a volume change.
	while ([NSApp runModalSession: session] == NSRunContinuesResponse) {
	    // Any mouse click events that do not change the slider value should abort.
	    NSEvent *event = [NSApp currentEvent];
	    unsigned int eventTypeMask = NSEventMaskFromType([event type]);
	    if (eventTypeMask & (NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask)) {
		[NSApp preventWindowOrdering];
		[NSApp discardEventsMatchingMask: NSAnyEventMask beforeEvent: event];
		break;
	    }
	    if (eventTypeMask & (NSKeyDownMask | NSKeyUpMask)) {
		unsigned short keyCode = [event keyCode];
		if (keyCode == 53 || keyCode == 36 || keyCode == 76) { // escape, return, enter
		    [NSApp discardEventsMatchingMask: NSAnyEventMask beforeEvent: event];
		    break;
		}
	    }
	}
        [NSApp endModalSession: session];
        [window close];
        [self autorelease];
        // XXX make sure window and self are released
    }
    return self;
}

- (void)dealloc;
{
    [delegate release];
    [super dealloc];
}

- (IBAction)volumeSet:(NSSlider *)sender;
{
    [delegate volumeController: self didSetVolume: [sender floatValue]];
    [NSApp stopModal];
}

@end