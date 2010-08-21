//
//  PSApplication.m
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSApplication.h"
#import "PSAlarmSetController.h"
#import "PSAlarmAlertController.h"
#import "PSAlarmsController.h"
#import "PSPreferencesController.h"
#import "NJRReadMeController.h"
#import "NJRSoundManager.h"
#import "PSAlarm.h"
#import "PSAlarms.h"
#import "PSTimer.h"
#import "NJRHotKey.h"
#import "NSWindowCollectionBehavior.h"

#import <QuartzCore/QuartzCore.h>

NSString * const PSApplicationWillReopenNotification = @"PSApplicationWillReopenNotification";

@interface PSApplication (Private)
- (void)_updateDockTile:(PSTimer *)timer;
@end

@implementation PSApplication

- (void)finishLaunching;
{
    appIconImage = [[NSImage imageNamed: @"NSApplicationIcon"] retain];
    [[NSNotificationCenter defaultCenter] addObserver: [PSAlarmAlertController class] selector: @selector(controllerWithTimerExpiredNotification:) name: PSAlarmTimerExpiredNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(nextAlarmDidChange:) name: PSAlarmsNextAlarmDidChangeNotification object: nil];
    // XXX exception handling
    [PSAlarms setUp];
    [self setDelegate: self];
    [PSPreferencesController readPreferences];
    [super finishLaunching];
}

#pragma mark actions

- (IBAction)showHelp:(id)sender;
{
    [NJRReadMeController readMeControllerWithRTFDocument: [[NSBundle mainBundle] pathForResource: @"Read Me" ofType: @"rtfd"]];
}

- (IBAction)stopAlerts:(id)sender;
{
    [PSAlarmAlertController stopAlerts: sender];
}

- (IBAction)orderFrontSetAlarmPanel:(id)sender;
{
    NSWindow *window = [alarmSetController window];
    if ([window respondsToSelector: @selector(setCollectionBehavior:)]) { // 10.5-only
	// XXX bug workaround - NSWindowCollectionBehaviorMoveToActiveSpace is what we want, but it doesn't work correctly, probably because we have a "chicken and egg" problem as the panel isn't visible when the app is hidden
	[window setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
	[alarmSetController showWindow: self];
    	[window performSelector: @selector(setCollectionBehavior:) withObject:
	 (id)NSWindowCollectionBehaviorDefault afterDelay: 0];
	[NSApp activateIgnoringOtherApps: YES]; // XXX causes title bar to flash
	return;
    }
    [NSApp activateIgnoringOtherApps: YES];
    [alarmSetController showWindow: self];
}

- (void)orderFrontSetAlarmPanelIfPreferencesNotKey:(id)sender;
{
    if ([self isActive] && preferencesController != nil && [[preferencesController window] isKeyWindow])
	return;

    [self orderFrontSetAlarmPanel: sender];
}


- (IBAction)orderFrontAlarmsPanel:(id)sender;
{
    [NSApp activateIgnoringOtherApps: YES];
    if (alarmsController == nil) {
        alarmsController = [[PSAlarmsController alloc] init];
    }
    [alarmsController showWindow: self];
}

- (IBAction)orderFrontPreferencesPanel:(id)sender;
{
    if (preferencesController == nil) {
        preferencesController = [[PSPreferencesController alloc] init];
    }
    [preferencesController showWindow: self];
}

#pragma mark Spaces interaction

- (void)orderOutSetAlarmPanelIfHidden;
{
    // prevent set alarm panel from "yanking" focus from an alarm notification, thereby obscuring the notification
    if ([NSApp isActive])
	return;
    
    NSWindow *window = [alarmSetController window];
    if (![window isVisible])
	return;

    [window orderOut: self];
}

#pragma mark update timer

- (void)_resetUpdateTimer;
{
    if (dockUpdateTimer != nil) {
        [dockUpdateTimer invalidate];
        [dockUpdateTimer release];
        dockUpdateInterval = 0;
        dockUpdateTimer = nil;
    }
}

- (void)_setUpdateTimerForInterval:(NSTimeInterval)interval alarm:(PSAlarm *)alarm repeats:(BOOL)repeats;
{
    dockUpdateTimer = [PSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(_updateDockTile:) userInfo: alarm repeats: repeats];
    [dockUpdateTimer retain];
    dockUpdateInterval = interval; // because [timer timeInterval] always returns 0 once set
}

- (void)nextAlarmDidChange:(NSNotification *)notification;
{
    PSAlarm *nextAlarm = [notification object];
    // NSLog(@"nextAlarmDidChange: %@", nextAlarm);
    [self _resetUpdateTimer];
    if (nextAlarm == nil) {
        [NSApp setApplicationIconImage: appIconImage];
    } else {
        [self _updateDockTile: nil];
    }
}

#pragma mark time remaining display

- (NSImage *)iconImageWithAlarm:(PSAlarm *)alarm;
{
	NSMutableDictionary *atts = [NSMutableDictionary dictionary];
	NSSize imageSize = [appIconImage size];
	NSImage *tile = [[NSImage alloc] initWithSize: imageSize];
	NSSize textSize;
	NSPoint textOrigin;
	NSRect frameRect;
	float fontSize = 37;
    NSString *tileString = [alarm timeRemainingString];

	do {
		fontSize -= 1;
		[atts setObject: [NSFont boldSystemFontOfSize: fontSize] forKey: NSFontAttributeName];
		textSize = [tileString sizeWithAttributes: atts];
	} while (textSize.width > imageSize.width - 8);

	textOrigin = NSMakePoint(imageSize.width / 2 - textSize.width / 2,
							 imageSize.height / 2 - textSize.height / 2);
	frameRect = NSInsetRect(NSMakeRect(textOrigin.x, textOrigin.y, textSize.width, textSize.height), -4, -2);

	[tile lockFocus];
	// draw the grayed-out app icon
	[appIconImage dissolveToPoint: NSZeroPoint fraction: 0.5f];
	// draw the frame
	[[NSColor colorWithCalibratedWhite: 0.1f alpha: 0.5f] set];
	NSRectFill(frameRect);
	// draw a gray two-pixel text shadow
	[atts setObject: [NSColor grayColor] forKey: NSForegroundColorAttributeName];
	textOrigin.x++; textOrigin.y--;
	[tileString drawAtPoint: textOrigin withAttributes: atts];
	textOrigin.x++; textOrigin.y--;
	[tileString drawAtPoint: textOrigin withAttributes: atts];
	// draw white text
	textOrigin.x -= 2; textOrigin.y += 2;
	[atts setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
	[tileString drawAtPoint: textOrigin withAttributes: atts];
	[tile unlockFocus];

	return [tile autorelease];
}

- (void)showTimeRemainingForAlarm:(PSAlarm *)alarm fromWindow:(NSWindow *)window;
{
	NSScreen *screen = [window screen];
	NSWindow *screenWindow =
	[[NSWindow alloc]initWithContentRect: [window frame]
							   styleMask: NSBorderlessWindowMask
								 backing: NSBackingStoreRetained
								   defer: NO
								  screen: screen];

	[screenWindow setLevel: NSPopUpMenuWindowLevel + 1];
    [screenWindow setBackgroundColor: [NSColor clearColor]];
    [screenWindow setHasShadow: NO];
    [screenWindow setOpaque: NO];
 	[screenWindow setIgnoresMouseEvents: YES];

    NSView *contentView = [screenWindow contentView];
	[contentView setWantsLayer: YES];

    CALayer *rootLayer = [contentView layer];
	[rootLayer setLayoutManager: [CAConstraintLayoutManager layoutManager]];

    CALayer *iconLayer = [CALayer layer];
	NSImage *iconImage = [self iconImageWithAlarm: alarm];
	NSSize size = [[iconImage bestRepresentationForDevice: [screen deviceDescription]] size];
	[iconLayer setBounds: CGRectMake(0, 0, size.width, size.height)];
	[iconLayer setContents: iconImage];
	[iconLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMidX
														 relativeTo: @"superlayer"
														  attribute: kCAConstraintMidX]];
	[iconLayer addConstraint: [CAConstraint constraintWithAttribute: kCAConstraintMidY
														 relativeTo: @"superlayer"
														  attribute: kCAConstraintMidY]];
	[iconLayer setOpacity: 0]; // don't "bounce" at end
    [rootLayer addSublayer: iconLayer];
	[rootLayer layoutIfNeeded];

	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath: @"opacity"];
	[animation setFromValue: [NSNumber numberWithFloat: 1]];
	[animation setToValue: [NSNumber numberWithFloat: 0]];
	[animation setDuration: 1];
	[animation setTimingFunction: [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut]];
	[iconLayer addAnimation: animation forKey: @"opacity"];

	[screenWindow makeKeyAndOrderFront: nil];
	// XXX remove window, etc.
}

- (void)_updateDockTile:(PSTimer *)timer;
{
    PSAlarm *alarm = [timer userInfo];
    if (timer == nil) alarm = [[PSAlarms allAlarms] nextAlarm];
    if (alarm == nil) return;
	[NSApp setApplicationIconImage: [self iconImageWithAlarm: alarm]];

	NSTimeInterval timeRemaining = ceil([alarm timeRemaining]);
    // NSLog(@"_updateDockTile > time remaining %@ (%.6lf), last time interval %.6lf", tileString, timeRemaining, dockUpdateInterval);
    if (timeRemaining > 61) {
        NSTimeInterval nextUpdate = ((unsigned long long)timeRemaining) % 60;
        if (nextUpdate <= 1) nextUpdate = 60;
        [self _resetUpdateTimer];
        [self _setUpdateTimerForInterval: nextUpdate alarm: alarm repeats: NO];
        // NSLog(@"_updateDockTile > set timer for %.0lf seconds", nextUpdate);
    } else if (timer == nil || dockUpdateInterval > 1) {
        [self _resetUpdateTimer]; 
        [self _setUpdateTimerForInterval: 1 alarm: alarm repeats: YES];
        // NSLog(@"_updateDockTile > set timer for 1 second");
    } else if (timeRemaining <= 1) {
        [self _resetUpdateTimer];
    }
}

#pragma mark activation

- (void)activateIgnoringOtherApps;
{
    [self activateIgnoringOtherApps: YES];
}

@end

@implementation PSApplication (NSApplicationDelegate)

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;
{
    [[NSNotificationCenter defaultCenter] postNotificationName: PSApplicationWillReopenNotification object: self];
    // XXX sometimes alarmsExpiring is NO (?), and we display the alarm set controller on top of an expiring alarm, try to reproduce
    if (!flag && ![[PSAlarms allAlarms] alarmsExpiring] && [NSApp modalWindow] == nil)
        [alarmSetController showWindow: self];
    return YES;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender;
{
    NSMenu *dockMenu = [[NSMenu alloc] initWithTitle: @""];
    PSAlarms *alarms = [PSAlarms allAlarms];
    PSAlarm *nextAlarm = [alarms nextAlarm];
    NSMenuItem *item;
    if (nextAlarm == nil) {
        [dockMenu addItemWithTitle: @"No Pending Alarms" action: nil keyEquivalent: @""];
    } else {
        [dockMenu addItemWithTitle: @"Next Alarm" action: nil keyEquivalent: @""];
        [dockMenu addItemWithTitle: [NSString stringWithFormat: @"   %@", [nextAlarm message]] action: nil keyEquivalent: @""];
        [dockMenu addItemWithTitle: [NSString stringWithFormat: @"   %@ %@", [nextAlarm shortDateString], [nextAlarm timeString]] action: nil keyEquivalent: @""];
        [dockMenu addItemWithTitle: [NSString stringWithFormat: @"   Remaining: %@", [nextAlarm timeRemainingString]] action: nil keyEquivalent: @""];
    }
    [dockMenu addItem: [NSMenuItem separatorItem]];
    item = [dockMenu addItemWithTitle: NSLocalizedString(@"Set Alarm...", "Dock menu item") action: @selector(orderFrontSetAlarmPanel:) keyEquivalent: @""];
    [item setTarget: self];
    item = [dockMenu addItemWithTitle: [NSString stringWithFormat: NSLocalizedString(@"All Alarms (%d)", "Dock menu item (%d replaced by number of alarms)"), [alarms alarmCount]] action: @selector(orderFrontAlarmsPanel:) keyEquivalent: @""];
    [item setTarget: self];
    return [dockMenu autorelease];
}

@end

@implementation PSApplication (NSApplicationNotifications)

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
{
    // XXX import panel will not be frontmost window if you switch to another app while Pester is launching; Mac OS X bug?
    PSAlarms *allAlarms = [PSAlarms allAlarms];
    unsigned version1AlarmCount = [allAlarms countOfVersion1Alarms];
    if (version1AlarmCount > 0) {
        int answer = NSRunAlertPanel(@"Import alarms from older Pester version?", @"Pester found %u alarm%@ created with an older version. These alarms must be converted for use with this version of Pester, and will be unavailable in previous versions after conversion. New alarms created with this version of Pester will not appear in Pester version 1.1a3 or earlier.",
                                     @"Import", @"Discard", NSLocalizedString(@"Don't Import", "Pester <= 1.1a3 format alarms button"),
                                     version1AlarmCount, version1AlarmCount == 1 ? @"" : @"s");
        switch (answer) {
            case NSAlertDefaultReturn:
                @try {
                    [allAlarms importVersion1Alarms];
                } @catch (NSException *exception) {
                    NSRunAlertPanel(@"Error occurred importing alarms", @"Pester was unable to convert some alarms created with an older version. Those alarms which could be read have been converted. The previous-format alarms have been retained; try using an older version of Pester to read them.\n\n%@", nil, nil, nil, [exception reason]);
                    return;
                }
            case NSAlertAlternateReturn:
                [allAlarms discardVersion1Alarms];
                break;
            case NSAlertOtherReturn:
                break;
        }
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [NJRSoundManager restoreSavedDefaultOutputVolume];
    [NSApp setApplicationIconImage: appIconImage];
}

// calendar window (running in modal session) will appear even when app is in background; shouldn't
- (void)applicationWillBecomeActive:(NSNotification *)notification;
{
    NSWindow *modalWindow = [NSApp modalWindow];
    if (modalWindow != nil) [modalWindow makeKeyAndOrderFront: nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification;
{
    NSWindow *modalWindow = [NSApp modalWindow];
    if (modalWindow != nil) [modalWindow orderOut: nil];
}

@end
