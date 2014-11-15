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
    // On a quick click, the event may be a mouse down but the mouse button is no longer down.
    if (!(eventMask & (NSLeftMouseDownMask | NSRightMouseDownMask | NSOtherMouseDownMask)))
	return;
    if ([NSEvent pressedMouseButtons] == 0)
	[menu cancelTracking];
}

@end