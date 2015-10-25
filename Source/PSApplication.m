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
#import "PSGrowlController.h"
#import "PSPreferencesController.h"
#import "NJRReadMeController.h"
#import "PSAlarm.h"
#import "PSAlarms.h"
#import "PSTimer.h"
#import "NJRHotKey.h"

#ifndef NSUserNotification
#import "NSUserNotification.h"
#endif

#import "PFMoveApplication.h"
#import <QuartzCore/QuartzCore.h>

NSString * const PSApplicationWillReopenNotification = @"PSApplicationWillReopenNotification";

static NSString * const PSShowDockCountdown = @"PesterShowDockCountdown"; // NSUserDefaults key

@interface PSApplication (Private)
- (void)_updateDockTile:(PSTimer *)timer;
- (void)_resetUpdateTimer;
@end

@implementation PSApplication

+ (void)initialize;
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                 forKey: PSShowDockCountdown]];
}

- (void)finishLaunching;
{
    appIconImage = [[NSImage imageNamed: @"NSApplicationIcon"] retain];
    [[NSNotificationCenter defaultCenter] addObserver: [PSAlarmAlertController class] selector: @selector(controllerWithTimerExpiredNotification:) name: PSAlarmTimerExpiredNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(nextAlarmDidChange:) name: PSAlarmsNextAlarmDidChangeNotification object: nil];
    [PSAlarms setUp];
    [self setDelegate: self];
    [PSPreferencesController readPreferences];

    [[NSUserDefaults standardUserDefaults] addObserver: self forKeyPath: PSShowDockCountdown options: NSKeyValueObservingOptionNew context: nil];

    [super finishLaunching];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: PSShowDockCountdown]) {
        if ([[change objectForKey: NSKeyValueChangeNewKey] boolValue]) {
            [self _updateDockTile: nil];
        } else {
            [self _resetUpdateTimer];
            self.applicationIconImage = appIconImage;
        }
        return;
    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
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
    // XXX bug workaround - NSWindowCollectionBehaviorMoveToActiveSpace is what we want, but it doesn't work correctly, probably because we have a "chicken and egg" problem as the panel isn't visible when the app is hidden
    [window setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [alarmSetController showWindow: self];
    [window performSelector: @selector(setCollectionBehavior:) withObject:
     (id)NSWindowCollectionBehaviorDefault afterDelay: 0];
    [self activateIgnoringOtherApps: YES]; // XXX causes title bar to flash
}

- (void)orderFrontSetAlarmPanelIfPreferencesNotKey:(id)sender;
{
    if ([self isActive] && preferencesController != nil && [[preferencesController window] isKeyWindow])
	return;

    [self orderFrontSetAlarmPanel: sender];
}


- (IBAction)orderFrontAlarmsPanel:(id)sender;
{
    [self activateIgnoringOtherApps: YES];
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

- (void)orderFrontStandardAboutPanelWithOptions:(NSDictionary *)optionsDictionary;
{
    // XXX work around bug in OS X 10.7-10.11 where the Credits text is not centered (r. 14829080)
    NSSet *windowsBefore = [NSSet setWithArray: [self windows]];

    // change credits font to current system font
    NSData *creditsData = [NSData dataWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Credits" ofType: @"html"]];
    NSMutableAttributedString *credits = [[NSMutableAttributedString alloc] initWithHTML: creditsData documentAttributes: nil];
    NSString *systemFontFamily = [[NSFont systemFontOfSize: [NSFont labelFontSize]].fontDescriptor objectForKey: NSFontFamilyAttribute];

    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    NSRange effectiveRange = {0, 0};
    NSUInteger length = credits.length;
    while (NSMaxRange(effectiveRange) < length) {
        NSFont *font = [credits attribute: NSFontAttributeName atIndex: NSMaxRange(effectiveRange) effectiveRange: &effectiveRange];
        font = [fontManager convertFont: font toFamily: systemFontFamily];
        [credits addAttribute: NSFontAttributeName value: font range: effectiveRange];
    }

    NSMutableDictionary *optionsWithCredits = optionsDictionary == nil ? [[NSMutableDictionary alloc] initWithCapacity: 1] : [optionsDictionary mutableCopy];
    optionsWithCredits[@"Credits"] = credits;
    [credits release];

    [super orderFrontStandardAboutPanelWithOptions: optionsWithCredits];
    [optionsWithCredits release];

    for (NSWindow *window in [self windows]) {
        if ([windowsBefore containsObject: window])
            continue;

        for (NSView *view in [[window contentView] subviews]) {
            if (![view isKindOfClass:[NSScrollView class]])
                continue;

            NSClipView *clipView = [(NSScrollView *)view contentView];
            NSRect clipViewFrame = [clipView frame];
            NSView *documentView = [clipView documentView];
            NSRect documentViewFrame = [documentView frame];

            if (clipViewFrame.size.height != documentViewFrame.size.height)
                continue; // don't mess with a scrollable view

            if (clipViewFrame.size.width != documentViewFrame.size.width) {
                documentViewFrame.size.width = clipViewFrame.size.width;
                [documentView setFrame: documentViewFrame];
                break;
            }
        }
        break;
    }
}

#pragma mark Spaces interaction

- (void)orderOutSetAlarmPanelIfHidden;
{
    // prevent set alarm panel from "yanking" focus from an alarm notification, thereby obscuring the notification
    if ([self isActive])
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
    if (![[NSUserDefaults standardUserDefaults] boolForKey: PSShowDockCountdown])
        return;

    PSAlarm *nextAlarm = [notification object];
    // NSLog(@"nextAlarmDidChange: %@", nextAlarm);
    [self _resetUpdateTimer];
    if (nextAlarm == nil) {
        [self setApplicationIconImage: appIconImage];
    } else {
        [self _updateDockTile: nil];
    }
}

#pragma mark time remaining display

- (NSImage *)iconImageWithAlarm:(PSAlarm *)alarm;
{
    NSSize imageSize = [appIconImage size];
    NSImage *tile = nil;

    BOOL (^drawingHandler)(NSRect) = ^(NSRect dstRect) {
        NSString *tileString = [alarm timeRemainingString];
        NSMutableDictionary *atts = [NSMutableDictionary dictionary];
        BOOL useBoldFont = (NJROSXMinorVersion() < 10);
        float fontSize = 148;
        NSSize textSize;

        do {
            fontSize -= 1;
            NSFont *font;
            if (useBoldFont) {
                font = [NSFont boldSystemFontOfSize: fontSize];
            } else {
                if ([NSFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)])
                    font = [NSFont monospacedDigitSystemFontOfSize: fontSize weight: NSFontWeightRegular];
                else
                    font = [NSFont systemFontOfSize: fontSize];
            }
            [atts setObject: font forKey: NSFontAttributeName];
            textSize = [tileString sizeWithAttributes: atts];
        } while (textSize.width > imageSize.width - 80);

        NSPoint textOrigin = NSMakePoint(imageSize.width / 2 - textSize.width / 2,
                                         imageSize.height / 2 - textSize.height / 2);
        NSRect frameRect = NSInsetRect(NSMakeRect(textOrigin.x, textOrigin.y, textSize.width, textSize.height), -40, -8);

        // draw the grayed-out app icon
        [appIconImage drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 0.5f];
        // draw the frame
        [[NSColor colorWithCalibratedWhite: 0.1f alpha: 0.6f] set];
        float radius = frameRect.size.height / 2;
        // XXX this is opaque when called as a drawing handler and translucent otherwise
        [[NSBezierPath bezierPathWithRoundedRect: frameRect xRadius: radius yRadius: radius] fill];
        // draw text
        if (useBoldFont) {
            NSShadow *shadow = [[NSShadow alloc] init];
            [shadow setShadowOffset: NSMakeSize(0, -8)];
            [shadow setShadowBlurRadius: 12];
            [atts setObject: shadow forKey: NSShadowAttributeName];
            [shadow release];
        }
        [atts setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
        [tileString drawAtPoint: textOrigin withAttributes: atts];
        if (tile != nil) {
            [tile unlockFocus];
        }
        return YES;
    };

    tile = [NSImage imageWithSize: imageSize flipped: NO drawingHandler: drawingHandler];
    return tile;
}

- (void)selectAlarmInAlarmsPanel:(PSAlarm *)alarm;
{
    if (![alarm isValid])
        return;

    [self orderFrontAlarmsPanel: nil];
    [alarmsController selectAlarm: alarm];
}

- (void)showTimeRemainingForAlarm:(PSAlarm *)alarm;
{
    [[PSGrowlController sharedController]
     notifyWithTitle: [alarm message]
     description: [NSString stringWithFormat: @"Alarm set for %@ from now.",
		   [[alarm intervalString] lowercaseString]]
     notificationName: @"Alarm Set"
     isSticky: NO
     target: self
     selector: @selector(selectAlarmInAlarmsPanel:)
     object: alarm
     onlyOnClick: YES];
}

- (void)_updateDockTile:(PSTimer *)timer;
{
    PSAlarm *alarm = [timer userInfo];
    if (timer == nil) alarm = [[PSAlarms allAlarms] nextAlarm];
    if (alarm == nil) return;
	[self setApplicationIconImage: [self iconImageWithAlarm: alarm]];

    NSTimeInterval timeRemaining = [alarm timeRemaining];
    // NSLog(@"_updateDockTile > time remaining %@ (%.8lfs), last update interval %.8lfs", [alarm timeRemainingString], timeRemaining, dockUpdateInterval);
    if (timeRemaining > 61) {
        [self _resetUpdateTimer];
        [self _setUpdateTimerForInterval: fmod(timeRemaining, 60) alarm: alarm repeats: NO];
        // NSLog(@"_updateDockTile > set timer for %.8lfs", fmod(timeRemaining, 60));
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
    if (!flag && ![[PSAlarms allAlarms] alarmsExpiring] && [self modalWindow] == nil)
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
    // NSLog(@"time to -applicationDidFinishLaunching: %f", clock() / (float)CLOCKS_PER_SEC);
    PSAlarms *allAlarms = [PSAlarms allAlarms];
    NSUInteger version1AlarmCount = [allAlarms countOfVersion1Alarms];
    if (version1AlarmCount > 0) {
        NSInteger answer = NSRunAlertPanel(@"Import alarms from older Pester version?", @"Pester found %u alarm%@ created with an older version. These alarms must be converted for use with this version of Pester, and will be unavailable in previous versions after conversion. New alarms created with this version of Pester will not appear in Pester version 1.1a3 or earlier.",
                                     @"Import", @"Discard", NSLocalizedString(@"Don't Import", "Pester <= 1.1a3 format alarms button"),
                                     (unsigned)version1AlarmCount, version1AlarmCount == 1 ? @"" : @"s");
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

    NSUserNotification *launchUserNotification = [[notification userInfo] objectForKey: NSApplicationLaunchUserNotificationKey];
    if (launchUserNotification != nil) {
        NSUserNotificationCenter *userNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
        [[userNotificationCenter delegate] userNotificationCenter: userNotificationCenter didActivateNotification: launchUserNotification];
    }

    PFMoveToApplicationsFolderIfNecessary();
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [self setApplicationIconImage: appIconImage];
}

// calendar window (running in modal session) will appear even when app is in background; shouldn't
- (void)applicationWillBecomeActive:(NSNotification *)notification;
{
    NSWindow *modalWindow = [self modalWindow];
    if (modalWindow != nil) [modalWindow makeKeyAndOrderFront: nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification;
{
    NSWindow *modalWindow = [self modalWindow];
    if (modalWindow != nil) [modalWindow orderOut: nil];
}

@end
