//
//  PSApplication.m
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSApplication.h"
#import "PSAlarmSetController.h"
#import "PSAlarmNotifierController.h"
#import "PSAlarmsController.h"
#import "PSAlarm.h"
#import "PSAlarms.h"

@implementation PSApplication

- (void)finishLaunching;
{
    appIconImage = [[NSImage imageNamed: @"NSApplicationIcon"] retain];
    [[NSNotificationCenter defaultCenter] addObserver: [PSAlarmNotifierController class] selector: @selector(controllerWithTimerExpiredNotification:) name: PSAlarmTimerExpiredNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(nextAlarmDidChange:) name: PSAlarmsNextAlarmDidChangeNotification object: nil];
    [PSAlarms setUp];
    [self setDelegate: self];
    [super finishLaunching];
}

- (IBAction)showHelp:(id)sender;
{
    [[NSWorkspace sharedWorkspace] openFile: [[NSBundle mainBundle] pathForResource: @"Read Me" ofType: @"rtfd"]];
}

- (IBAction)orderFrontSetAlarmPanel:(id)sender;
{
    [NSApp activateIgnoringOtherApps: YES];
    [alarmSetController showWindow: self];
}

- (IBAction)orderFrontAlarmsPanel:(id)sender;
{
    [NSApp activateIgnoringOtherApps: YES];
    if (alarmsController == nil) {
        alarmsController = [[PSAlarmsController alloc] init];
    }
    [alarmsController showWindow: self];
}

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
    dockUpdateTimer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(_updateDockTile:) userInfo: alarm repeats: repeats];
    [dockUpdateTimer retain];
    dockUpdateInterval = interval; // because [timer timeInterval] always returns 0 once set
}

- (void)_updateDockTile:(NSTimer *)timer;
{
    PSAlarm *alarm = [timer userInfo];
    NSTimeInterval alarmInterval;
    NSString *tileString;
    if (timer == nil) alarm = [[PSAlarms allAlarms] nextAlarm];
    if (alarm == nil) return;
    tileString = [alarm timeRemainingString];
    {
        NSMutableDictionary *atts = [NSMutableDictionary dictionary];
        NSSize imageSize = [appIconImage size];
        NSImage *tile = [[NSImage alloc] initWithSize: imageSize];
        NSSize textSize;
        NSPoint textOrigin;
        NSRect frameRect;
        float fontSize = 37;
        
        do {
            fontSize -= 1;
            [atts setObject: [NSFont boldSystemFontOfSize: fontSize] forKey: NSFontAttributeName];
            textSize = [tileString sizeWithAttributes: atts];
        } while (textSize.width > imageSize.width - 8);

        textOrigin = NSMakePoint(imageSize.width / 2 - textSize.width / 2,
                                 imageSize.height / 2 - textSize.height / 2);
        frameRect = NSInsetRect(NSMakeRect(textOrigin.x, textOrigin.y, textSize.width, textSize.height),
                                -4, -2);
        
        [tile lockFocus];
        // draw the grayed-out app icon
        [appIconImage dissolveToPoint: NSZeroPoint fraction: 0.5];
        // draw the frame
        [[NSColor colorWithCalibratedWhite: 0.1 alpha: 0.5] set];
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
        [NSApp setApplicationIconImage: tile];
        [tile release];
    }
    alarmInterval = [alarm interval];
    // NSLog(@"_updateDockTile > time remaining %@ (%.0lf), last time interval %.0lf", tileString, alarmInterval, dockUpdateInterval);
    if (alarmInterval > 61) {
        NSTimeInterval nextUpdate = ((unsigned long long)alarmInterval) % 60;
        if (nextUpdate <= 1) nextUpdate = 60;
        [self _resetUpdateTimer];
        [self _setUpdateTimerForInterval: nextUpdate alarm: alarm repeats: NO];
        // NSLog(@"_updateDockTile > set timer for %.0lf seconds", nextUpdate);
    } else if (timer == nil || dockUpdateInterval > 1) {
        [self _resetUpdateTimer];
        [self _setUpdateTimerForInterval: 1 alarm: alarm repeats: YES];
        // NSLog(@"_updateDockTile > set timer for 1 second");
    } else if (alarmInterval < 2) {
        [self _resetUpdateTimer];
    }
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

@end

@implementation PSApplication (NSApplicationDelegate)

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;
{
    if (!flag) [alarmSetController showWindow: self];
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
    item = [dockMenu addItemWithTitle: @"Set AlarmÉ" action: @selector(orderFrontSetAlarmPanel:) keyEquivalent: @""];
    [item setTarget: self];
    item = [dockMenu addItemWithTitle: [NSString stringWithFormat: @"All Alarms (%d)É", [alarms alarmCount]] action: @selector(orderFrontAlarmsPanel:) keyEquivalent: @""];
    [item setTarget: self];
    return [dockMenu autorelease];
}

@end

@implementation PSApplication (NSApplicationNotifications)

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [NSApp setApplicationIconImage: appIconImage];
}

@end
