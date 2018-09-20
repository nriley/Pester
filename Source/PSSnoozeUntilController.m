//
//  PSSnoozeUntilController.m
//  Pester
//
//  Created by Nicholas Riley on Sun Feb 16 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSAlarmNotifierController.h"
#import "PSCalendarController.h"
#import "PSSnoozeUntilController.h"
#import "PSTimeDateEditor.h"
#import "NSCalendarDate-NJRExtensions.h"

@interface PSSnoozeUntilController (PSSnoozeUntilControllerRuntime)
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(PSAlarmNotifierController *)aController;
@end

@implementation PSSnoozeUntilController

+ (PSSnoozeUntilController *)snoozeUntilControllerWithNotifierController:(PSAlarmNotifierController *)aController;
{
    return [[self alloc] initWithNotifierController: aController];
}

- (id)initWithNotifierController:(PSAlarmNotifierController *)aController;
{
    if ( (self = [self initWithWindowNibName: @"Snooze until"]) != nil) {
        NSWindow *window = [self window];
        alarm = [[PSAlarm alloc] init];
        snoozeInterval = [aController snoozeInterval];
        [alarm setInterval: snoozeInterval];
	timeDateEditor = [[PSTimeDateEditor alloc] initWithTimeField: timeOfDay dateField: timeDate completions: timeDateCompletions controller: self];
        if ([alarm isValid]) {
	    // [alarm time] works fine for display, but we can't use it overall until we've moved off NSCalendarDate
            [timeOfDay setObjectValue: [alarm date]];
            [timeDate setObjectValue: [alarm date]];
        }
        [self update: self];
        
        [NSApp beginSheet: window modalForWindow: [aController window] modalDelegate: self didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: aController];
    }
    return self;
}

- (void)dealloc;
{
    [timeDateEditor release];
    [alarm release];
    [super dealloc];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(PSAlarmNotifierController *)aController;
{
    if (returnCode == NSModalResponseAbort) {
        [aController setSnoozeInterval: snoozeInterval];
    } else {
        [aController snoozeUntilDate: [alarm date]];
    }
    [sheet close];
}

// XXX yuck, should not be duplicating this method between PSAlarmSetController and PSSnoozeUntilController
// XXX with -[NSControl currentEditor] don't need to compare?  Also check -[NSControl validateEditing]
- (id)objectValueForTextField:(NSTextField *)field whileEditing:(id)sender;
{
    if (sender == field) {
        NSString *stringValue = [[[self window] fieldEditor: NO forObject: field] string];
        id obj = nil;
        [[field formatter] getObjectValue: &obj forString: stringValue errorDescription: NULL];
        // NSLog(@"from field editor: %@", obj);
        return obj;
    } else {
        // NSLog(@"from field: %@", [field objectValue]);
        return [field objectValue];
    }
}

#pragma mark date setting

- (void)setAlarmDateAndInterval:(id)sender;
{
    [alarm setForDate: [self objectValueForTextField: timeDate whileEditing: sender]
               atTime: [self objectValueForTextField: timeOfDay whileEditing: sender]];
}

// Be careful not to hook up any of the text fields' actions to update: because we handle them in controlTextDidChange: instead.  If we could get the active text field somehow via public API (guess we could use controlTextDidBegin/controlTextDidEndEditing) then we'd not need to overload the update sender for this purpose.  Or, I guess, we could use another method other than update.  It should not be this hard to implement what is essentially standard behavior.  Sigh.
// Note: finding out whether a given control is editing is easier.  See: <http://cocoa.mamasam.com/COCOADEV/2002/03/2/28501.php>.

- (IBAction)update:(id)sender;
{
    BOOL isValid;
    [self setAlarmDateAndInterval: sender];
    isValid = [alarm isValid];
    [snoozeButton setEnabled: isValid];
    if (!isValid) {
        [messageField setStringValue: [alarm invalidMessage]];
    } else {
        [messageField setStringValue: @""];
    }
}

- (IBAction)dateCompleted:(NSPopUpButton *)sender;
{
    [timeDate setStringValue: [sender titleOfSelectedItem]];
    [self update: sender];
}

#pragma mark calendar

- (IBAction)showCalendar:(NSButton *)sender;
{
    NSCalendarDate *date = [NSCalendarDate dateForDay: [timeDate objectValue]];
    [timeDate selectText: nil];
    [PSCalendarController controllerWithDate: date delegate: self];
}

- (void)calendarController:(PSCalendarController *)calendar didSetDate:(NSCalendarDate *)date;
{
    [timeDate setObjectValue: date];
    [self update: self];
}

- (NSView *)calendarControllerLaunchingView:(PSCalendarController *)controller;
{
    return timeCalendarButton;
}

#pragma mark actions

- (IBAction)close:(id)sender;
{
    [NSApp endSheet: [self window] returnCode: NSModalResponseAbort];
}

- (IBAction)snooze:(NSButton *)sender;
{
    if ([alarm isValid]) {
        [NSApp endSheet: [self window] returnCode: NSModalResponseStop];
    } else {
        [messageField setStringValue: [@"Unable to snooze. " stringByAppendingString: [alarm invalidMessage]]];
        [sender setEnabled: NO];
    }
}

@end

@implementation PSSnoozeUntilController (NSControlSubclassNotifications)

// called because we're the delegate

- (void)controlTextDidChange:(NSNotification *)notification;
{
    [self update: [notification object]];
}

@end

@implementation PSSnoozeUntilController (NSWindowDelegate)

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client;
{
    if (client == timeDate)
	return [timeDateEditor dateFieldEditor];
    
    return nil;
}

@end

@implementation PSSnoozeUntilController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    [self autorelease];
}

@end
