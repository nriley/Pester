//
//  PSVolumeController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSVolumeController.h"
#import "NJRNonCenteringWindow.h"
#import "NJRSoundDevice.h"
#include <Carbon/Carbon.h>

@interface NSMenu (SnowLeopardAdditions)
- (BOOL)popUpMenuPositioningItem:(NSMenuItem *)item atLocation:(NSPoint)location inView:(NSView *)view;
- (void)setAllowsContextMenuPlugIns:(BOOL)allows;
- (void)cancelTracking;
@end

@interface NSMenuItem (SnowLeopardAdditions)
- (void)setView:(NSView *)view;
@end

@implementation PSVolumeController

+ (PSVolumeController *)controllerWithVolume:(float)volume delegate:(id)aDelegate;
{
    return [[self alloc] initWithVolume: volume delegate: aDelegate];
}

- (id)initWithVolume:(float)volume delegate:(id)aDelegate;
{
    if ( (self = [self initWithWindowNibName: @"Volume"]) != nil) {
        [self window]; // connect outlets

	if ([NJRSoundDevice volumeIsNotMutedOrInvalid: volume])
            [volumeSlider setFloatValue: volume];

        delegate = [aDelegate retain];

	NSView *view = [aDelegate volumeControllerLaunchingView: self];

	// In 10.6, we can no longer force the modal session to work by "seeding" the slider with a mouse-down event.
	// Instead, use a menu.  (This should mostly work on 10.5 too, but is currently untested.)
	if ([NSMenu instancesRespondToSelector: @selector(popUpMenuPositioningItem:atLocation:inView:)]) {
	    menu = [[NSMenu alloc] initWithTitle: @""];
	    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
	    [menuItem setView: contentView];
	    [menu addItem: menuItem];
	    [menuItem release];
	    NSPoint point;
	    if (view != nil) {
		NSSize size = [view bounds].size;
		point = [view isFlipped] ? NSMakePoint(0, size.height) : NSZeroPoint;
	    } else {
		point = [NSEvent mouseLocation];
	    }
	    [menu setAllowsContextMenuPlugIns: NO];
	    // replace with http://waffle.wootest.net/2007/08/07/popping-up-a-menu-in-cocoa/
	    [menu popUpMenuPositioningItem: nil atLocation: point inView: view];
	    [menu release];
	} else {
	    NSWindow *window = [[NJRNonCenteringWindow alloc] initWithContentRect: [contentView bounds] styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];
	    [window setContentView: contentView];
	    [window setOpaque: NO];
	    [window setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.81f alpha: 0.9f]];
	    [window setHasShadow: YES];
	    [window setOneShot: YES];
	    [window setDelegate: self];

	    if (view != nil) {
		NSWindow *parentWindow = [view window];
		NSRect rect = [parentWindow convertRectToScreen: [view convertRect: [view bounds] toView: nil]];
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
	    [volumeSlider mouseDown: [NSApp currentEvent]];
	    [NSApp runModalSession: session];
	    [NSApp endModalSession: session];
	    [window close];
	}

        [self autorelease];
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
    // XXX don't delay preview for keyboard adjustment
    [delegate volumeController: self didSetVolume: [sender floatValue]];
    unsigned eventMask = NSEventMaskFromType([[NSApp currentEvent] type]);
    // The event may simply be a mouse-up: close the menu.
    if (eventMask & (NSLeftMouseUpMask | NSRightMouseDownMask | NSOtherMouseDownMask))
	[menu cancelTracking];
    // On a quick click, the event may be a mouse down but the mouse button is no longer down.
    if (!(eventMask & (NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask)))
	return;
    if ([NSEvent pressedMouseButtons] == 0)
	[menu cancelTracking];
}

@end