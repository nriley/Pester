//
//  PSAlarmNotifierController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmNotifierController.h"
#import "PSAlarmAlertController.h"
#import "PSAlarm.h"
#import "PSApplication.h"
#import "PSNotifierAlert.h"
#import "PSSnoozeUntilController.h"
#import "NJRIntervalField.h"
#import "NSObject-PerformWhenIdle.h"

static NSString * const PSAlarmSnoozeInterval = @"Pester alarm snooze interval"; // NSUserDefaults key
static NSString * const PSAlarmNotifierWaitForIdle = @"PesterAlarmNotifierWaitForIdle"; // NSUserDefaults key

@interface PSAlarmNotifierController (Private)

- (void)update:(id)sender;
- (void)updateNextDateDisplay:(id)sender;

@end

@implementation PSAlarmNotifierController

// XXX should use NSNonactivatingPanelMask on 10.2?

- (id)initWithAlarm:(PSAlarm *)anAlarm;
{
    if ([self initWithWindowNibName: @"Notifier"]) {
        NSWindow *window = [self window];
        NSRect frameRect = [window frame];
        alarm = [anAlarm retain];
        [messageField setStringValue: [alarm message]];
        [dateField setStringValue: [alarm dateTimeString]];
        if (![self setSnoozeInterval: [alarm snoozeInterval]] &&
            ![self setSnoozeInterval: [[[NSUserDefaults standardUserDefaults] objectForKey: PSAlarmSnoozeInterval] doubleValue]])
            [self setSnoozeInterval: 15 * 60]; // 15 minutes
        if ([alarm isRepeating]) {
            [intervalField setStringValue:
                [NSString stringWithFormat: @"every %@", [alarm repeatIntervalString]]];
            [self updateNextDateDisplay: nil];
            updateTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(updateNextDateDisplay:) userInfo: nil repeats: YES];
            frameRect.size = [window maxSize];
        } else {
            frameRect.size = [window minSize];
        }
        [window setFrame: frameRect display: NO];
        [window center];
	if ([[NSUserDefaults standardUserDefaults] boolForKey: PSAlarmNotifierWaitForIdle])
	    [self performSelector: @selector(showWindow:) withObject: nil afterSystemIdleTime: 0.5];
	else
	    [self showWindow: nil];
    }
    return self;
}

- (IBAction)showWindow:(id)sender;
{
    [super showWindow: sender];
    [[self window] orderFrontRegardless];
    [(PSApplication *)NSApp orderOutSetAlarmPanelIfHidden];
}

- (void)dealloc;
{
    [alarm release]; alarm = nil;
    [updateTimer invalidate]; updateTimer = nil;
    [super dealloc];
}

- (void)updateNextDateDisplay:(id)sender;
{
    if (!canSnooze) {
        NSString *nextDateTimeString = [alarm nextDateTimeString];
        if (nextDateTimeString == nil) { // no longer repeating
            [updateTimer invalidate]; updateTimer = nil;
        } else {
            [nextDateField setStringValue: nextDateTimeString];
        }
    }
}

- (void)update:(id)sender;
{
    snoozeInterval = [snoozeIntervalField interval];
    canSnooze = (snoozeInterval > 0);
    if (canSnooze) [nextDateField setStringValue: @"after snooze"];
    [snoozeButton setEnabled: canSnooze];
    [canSnooze ? snoozeButton : okButton setKeyEquivalent: @"\r"];
    [canSnooze ? okButton : snoozeButton setKeyEquivalent: @""];
}

- (IBAction)close:(id)sender;
{
    [PSAlarmAlertController stopAlerts: sender];
    [self retain];
    [self close]; // releases self in windowWillClose:
    [[PSNotifierAlert alert] completedForAlarm: alarm];
    [self release];
}

- (IBAction)snoozeUntil:(NSMenuItem *)sender;
{
    [PSSnoozeUntilController snoozeUntilControllerWithNotifierController: self];
}

- (IBAction)snoozeIntervalUnitsChanged:(NSPopUpButton *)sender;
{
    if ([[sender selectedItem] tag] > 0) [self update: nil];
}

- (NSTimeInterval)snoozeInterval;
{
    return snoozeInterval;
}

- (BOOL)setSnoozeInterval:(NSTimeInterval)interval;
{
    snoozeInterval = interval;
    return [snoozeIntervalField setInterval: interval];
}

- (IBAction)snooze:(NSButton *)sender;
{
    snoozeInterval = [snoozeIntervalField interval];
    [alarm setSnoozeInterval: snoozeInterval];
    [[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithDouble: snoozeInterval] forKey: PSAlarmSnoozeInterval];
    [self close: sender];
}

- (void)snoozeUntilDate:(NSCalendarDate *)date;
{
    [alarm setSnoozeInterval: [date timeIntervalSinceNow]];
    [self close: self];
}

- (IBAction)stopRepeating:(NSButton *)sender;
{
    NSWindow *window = [self window];
    NSRect frameRect = [window frame];
    NSSize newSize = [window minSize];
    
    [alarm setRepeating: NO];
    [sender setEnabled: NO];
    frameRect.origin.y += frameRect.size.height - newSize.height;
    frameRect.size = newSize;
    [window setFrame: frameRect display: YES animate: YES];
}

@end

@implementation PSAlarmNotifierController (NSControlSubclassDelegate)

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error;
{
    if (control == snoozeIntervalField)
        [snoozeIntervalField handleDidFailToFormatString: string errorDescription: error label: @"snooze interval"];
    return NO;
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error;
{
    // NSLog(@"UPDATING FROM validation");
    [self update: control]; // switch to snooze if someone types something weird...
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;
{
    // NSLog(@"UPDATING from textView: %@", NSStringFromSelector(commandSelector));
    if (commandSelector == @selector(cancel:)) {
        // if someone just wants the stupid thing to go away and presses escape, don’t hinder them
        [self close: control];
        return YES;
    }
    // if someone invokes the default button or switches fields, don’t override it
    if (commandSelector == @selector(insertNewline:) ||
        commandSelector == @selector(insertTab:) ||
        commandSelector == @selector(insertBacktab:)) return NO;
    [self update: control]; // ...or if they type a navigation key...
    return NO; // we don’t handle it
}

@end

@implementation PSAlarmNotifierController (NSControlSubclassNotifications)

- (void)controlTextDidChange:(NSNotification *)notification;
{
    // NSLog(@"UPDATING FROM controlTextDidChange: %@", [notification object]);
    [self update: [notification object]]; // ...or if they modify the snooze interval
}

@end

@implementation PSAlarmNotifierController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    // can’t rely on dealloc to invalidate the timer, because it retains this object
    [updateTimer invalidate]; updateTimer = nil;
    [self release]; // in non-document-based apps, this is needed; see docs
}

@end