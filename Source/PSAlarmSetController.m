//
//  PSAlarmSetController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmSetController.h"
#import "PSAlarmAlertController.h"
#import "PSPowerManager.h"
#import "NJRDateFormatter.h"
#import "NJRFSObjectSelector.h"
#import "NJRIntervalField.h"
#import "NJRQTMediaPopUpButton.h"
#import "NJRVoicePopUpButton.h"
#import "NSString-NJRExtensions.h"
#import "NSAttributedString-NJRExtensions.h"
#import "NSCalendarDate-NJRExtensions.h"
#import <Carbon/Carbon.h>

#import "PSAlerts.h"
#import "PSDockBounceAlert.h"
#import "PSScriptAlert.h"
#import "PSNotifierAlert.h"
#import "PSBeepAlert.h"
#import "PSMovieAlert.h"
#import "PSSpeechAlert.h"
#import "PSWakeAlert.h"

/* Bugs to file:

• any trailing spaces: -> exception for +[NSCalendarDate dateWithNaturalLanguageString]:
 > NSCalendarDate dateWithNaturalLanguageString: '12 '
  format error: internal error

• NSDate natural language stuff in NSCalendarDate (why?), misspelled category name
• NSCalendarDate natural language stuff behaves differently from NSDateFormatter (AM/PM has no effect, shouldn't they share code?)
• descriptionWithCalendarFormat:, dateWithNaturalLanguageString: does not default to current locale, instead it defaults to US unless you tell it otherwise
• NSDateFormatter doc class description gives two examples for natural language that are incorrect, no link to NSDate doc that describes exactly how natural language dates are parsed
• NSTimeFormatString does not include %p when it should, meaning that AM/PM is stripped yet 12-hour time is still used
• NSNextDayDesignations, NSNextNextDayDesignations are noted as 'a string' in NSUserDefaults docs, but maybe they are actually an array, or either an array or a string, given their names?
• "Setting the Format for Dates" does not document how to get 1:15 AM, the answer is %1I - strftime has no exact equivalent; the closest is %l.  strftime does not permit numeric prefixes.  It also refers to "NSCalendar" when no such class exists.
• none of many mentions of NSAMPMDesignation indicates that they include the leading spaces (" AM", " PM").  In "Setting the Format for Dates", needs to mention that the leading spaces are not included in %p with strftime.  But if you use the NSCalendarDate stuff, it appears %p doesn't include the space (because it doesn't use the locale dictionary).
• If you feed NSCalendarDate dateWithNaturalLanguageString: an " AM"/" PM" locale, it doesn't accept that date format.
• descriptions for %X and %x are reversed (time zone is in %X, not %x)
• NSComboBox data source issues, can’t have it appear as “today” because the formatter doesn’t like that.  Should be able to enter text into the data source and have the formatter process it without altering it.
• too hard to implement date-only or time-only formatters
• should be able to specify that natural language favors date or time (10 = 10th of month, not 10am)
• please expose the iCal controls!

*/

static NSString * const PSAlertsSelected = @"Pester alerts selected"; // NSUserDefaults key
static NSString * const PSAlertsEditing = @"Pester alerts editing"; // NSUserDefaults key

@interface PSAlarmSetController (Private)

- (void)_readAlerts:(PSAlerts *)alerts;
- (BOOL)_setAlerts;
- (void)_stopUpdateTimer;

@end

@implementation PSAlarmSetController

- (void)awakeFromNib;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    alarm = [[PSAlarm alloc] init];
    [[self window] center];
    // XXX excessive retention of formatters?  check later...
    [timeOfDay setFormatter: [[NJRDateFormatter alloc] initWithDateFormat: [NJRDateFormatter localizedTimeFormatIncludingSeconds: NO] allowNaturalLanguage: YES]];
    [timeDate setFormatter: [[NJRDateFormatter alloc] initWithDateFormat: [NJRDateFormatter localizedDateFormatIncludingWeekday: NO] allowNaturalLanguage: YES]];
    {
        NSArray *dayNames = [defaults arrayForKey:
            NSWeekDayNameArray];
        NSArray *completions = [timeDateCompletions itemTitles];
        NSEnumerator *e = [completions objectEnumerator];
        NSString *title;
        int itemIndex = 0;
        NSRange matchingRange;
        while ( (title = [e nextObject]) != nil) {
            matchingRange = [title rangeOfString: @"«day»"];
            if (matchingRange.location != NSNotFound) {
                NSMutableString *format = [title mutableCopy];
                NSEnumerator *we = [dayNames objectEnumerator];
                NSString *dayName;
                [format deleteCharactersInRange: matchingRange];
                [format insertString: @"%@" atIndex: matchingRange.location];
                [timeDateCompletions removeItemAtIndex: itemIndex];
                while ( (dayName = [we nextObject]) != nil) {
                    [timeDateCompletions insertItemWithTitle: [NSString stringWithFormat: format, dayName] atIndex: itemIndex];
                    itemIndex++;
                }
            } else itemIndex++;
        }
    }
    [editAlert setIntValue: [defaults boolForKey: PSAlertsEditing]];
    {
        NSDictionary *plAlerts = [defaults dictionaryForKey: PSAlertsSelected];
        PSAlerts *alerts;
        if (plAlerts == nil) {
            alerts = [[PSAlerts alloc] initWithPesterVersion1Alerts];
        } else {
            NS_DURING
                alerts = [[PSAlerts alloc] initWithPropertyList: plAlerts];
            NS_HANDLER
                NSRunAlertPanel(@"Unable to restore alerts", @"Pester could not restore recent alert information for one or more alerts in the Set Alarm window.  The default set of alerts will be used instead.\n\n%@", nil, nil, nil, [localException reason]);
                alerts = [[PSAlerts alloc] initWithPesterVersion1Alerts];
            NS_ENDHANDLER
        }
        [self _readAlerts: alerts];
    }
    [timeDate setObjectValue: [NSDate date]];
    [self inAtChanged: nil]; // by convention, if sender is nil, we're initializing
    [self playSoundChanged: nil];
    [self doScriptChanged: nil];
    [self doSpeakChanged: nil];
    [self editAlertChanged: nil];
    [script setFileTypes: [NSArray arrayWithObjects: @"applescript", @"script", NSFileTypeForHFSTypeCode(kOSAFileType), NSFileTypeForHFSTypeCode('TEXT'), nil]];
    [notificationCenter addObserver: self selector: @selector(silence:) name: PSAlarmAlertStopNotification object: nil];
    [notificationCenter addObserver: self selector: @selector(playSoundChanged:) name: NJRQTMediaPopUpButtonMovieChangedNotification object: sound];
    [notificationCenter addObserver: self selector: @selector(applicationWillHide:) name: NSApplicationWillHideNotification object: NSApp];
    [notificationCenter addObserver: self selector: @selector(applicationDidUnhide:) name: NSApplicationDidUnhideNotification object: NSApp];
    [notificationCenter addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: NSApp];
    [voice setDelegate: self]; // XXX why don't we do this in IB?  It should use the accessor...
    [wakeUp setEnabled: [PSPowerManager autoWakeSupported]];
    // XXX workaround for 10.1.x and 10.2.x bug which sets the first responder to the wrong field alternately, but it works if I set the initial first responder to nil... go figure.
    [[self window] setInitialFirstResponder: nil];
    [[self window] makeKeyAndOrderFront: nil];
}

- (void)setStatus:(NSString *)aString;
{
    // NSLog(@"%@", alarm);
    if (aString != status) {
        [status release]; status = nil;
        status = [aString retain];
        [timeSummary setStringValue: status];
    }
}

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

#pragma mark date/interval setting

- (void)setAlarmDateAndInterval:(id)sender;
{
    if (isInterval) {
        [alarm setInterval: [timeInterval interval]];
    } else {
        [alarm setForDate: [self objectValueForTextField: timeDate whileEditing: sender]
                   atTime: [self objectValueForTextField: timeOfDay whileEditing: sender]];
    }
}

- (void)_stopUpdateTimer;
{
    [updateTimer invalidate]; [updateTimer release]; updateTimer = nil;
}

// XXX use OACalendar in popup like Palm Desktop?

- (IBAction)updateDateDisplay:(id)sender;
{
    // NSLog(@"updateDateDisplay: %@", sender);
    if ([alarm isValid]) {
        [self setStatus: [NSString stringWithFormat: @"Alarm will be set for %@ on %@", [alarm timeString], [alarm dateString]]];
        [setButton setEnabled: YES];
        if (updateTimer == nil || ![updateTimer isValid]) {
            // XXX this logic (and the timer) should really go into PSAlarm, to send notifications for status updates instead.  Timer starts when people are watching, stops when people aren't.
            // NSLog(@"setting timer");
            if (isInterval) {
                updateTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(updateDateDisplay:) userInfo: nil repeats: YES];
            } else {
                updateTimer = [NSTimer scheduledTimerWithTimeInterval: [alarm interval] target: self selector: @selector(updateDateDisplay:) userInfo: nil repeats: NO];
            }
            [updateTimer retain];
        }
    } else {
        [setButton setEnabled: NO];
        [self setStatus: [alarm invalidMessage]];
        [self _stopUpdateTimer];
    }
}

// Be careful not to hook up any of the text fields' actions to update: because we handle them in controlTextDidChange: instead.  If we could get the active text field somehow via public API (guess we could use controlTextDidBegin/controlTextDidEndEditing) then we'd not need to overload the update sender for this purpose.  Or, I guess, we could use another method other than update.  It should not be this hard to implement what is essentially standard behavior.  Sigh.
// Note: finding out whether a given control is editing is easier.  See: <http://cocoa.mamasam.com/COCOADEV/2002/03/2/28501.php>.

- (IBAction)update:(id)sender;
{
    // NSLog(@"update: %@", sender);
    [self setAlarmDateAndInterval: sender];
    [self updateDateDisplay: sender];
}

- (IBAction)inAtChanged:(id)sender;
{
    NSButtonCell *new = [inAtMatrix selectedCell], *old;
    isInterval = ([inAtMatrix selectedTag] == 0);
    old = [inAtMatrix cellWithTag: isInterval];
    NSAssert(new != old, @"in and at buttons should be distinct!");
    [old setKeyEquivalent: [new keyEquivalent]];
    [old setKeyEquivalentModifierMask: [new keyEquivalentModifierMask]];
    [new setKeyEquivalent: @""];
    [new setKeyEquivalentModifierMask: 0];
    [timeInterval setEnabled: isInterval];
    [timeIntervalUnits setEnabled: isInterval];
    [timeIntervalRepeats setEnabled: isInterval];
    [timeOfDay setEnabled: !isInterval];
    [timeDate setEnabled: !isInterval];
    [timeDateCompletions setEnabled: !isInterval];
    if (sender != nil)
        [[self window] makeFirstResponder: isInterval ? (NSTextField *)timeInterval : timeOfDay];
    // NSLog(@"UPDATING FROM inAtChanged");
    [self update: nil];
}

- (IBAction)dateCompleted:(NSPopUpButton *)sender;
{
    [timeDate setStringValue: [sender titleOfSelectedItem]];
    [self update: sender];
}

#pragma mark alert editing

- (IBAction)editAlertChanged:(id)sender;
{
    BOOL editAlertSelected = [editAlert intValue];
    NSView *editAlertControl = [editAlert controlView];
    NSWindow *window = [self window];
    NSRect frame = [window frame];
    if (editAlertSelected) {
        NSSize editWinSize = [window maxSize];
        [editAlertControl setNextKeyView: [displayMessage controlView]];
        frame.origin.y += frame.size.height - editWinSize.height;
        frame.size = editWinSize;
        [window setFrame: frame display: (sender != nil) animate: (sender != nil)];
        [self updateDateDisplay: sender];
        [alertTabs selectTabViewItemWithIdentifier: @"edit"];
    } else {
        NSSize viewWinSize = [window minSize];
        NSRect textFrame = [alertView frame];
        float textHeight;
        if (![self _setAlerts]) {
            [alertView setStringValue: [NSString stringWithFormat: @"Couldn’t process alert information.\n%@", status]];
        } else {
            NSAttributedString *string = [[alarm alerts] prettyList];
            if (string == nil) {
                [alertView setStringValue: @"Do nothing. Click the button labeled “Edit” to add an alert."];
            } else {
                [alertView setAttributedStringValue: string];
                [self updateDateDisplay: sender];
            }
        }
        if (sender != nil) { // nil == we're initializing, don't mess with focus
            NSResponder *oldResponder = [window firstResponder];
            // make sure focus doesn't get stuck in the edit tab: it is confusing and leaves behind artifacts
            if (oldResponder == editAlertControl || [oldResponder isKindOfClass: [NSView class]] && [(NSView *)oldResponder isDescendantOf: alertTabs])
                [window makeFirstResponder: messageField]; // would use editAlertControl, but can't get it to display anomaly-free.
            [self silence: sender];
        }
        // allow height to expand, though not arbitrarily (should still fit on an 800x600 screen)
        textHeight = [[alertView cell] cellSizeForBounds: NSMakeRect(0, 0, textFrame.size.width, 400)].height;
        textFrame.origin.y += textFrame.size.height - textHeight;
        textFrame.size.height = textHeight;
        [alertView setFrame: textFrame];
        viewWinSize.height += textHeight;
        [alertTabs selectTabViewItemWithIdentifier: @"view"];
        frame.origin.y += frame.size.height - viewWinSize.height;
        frame.size = viewWinSize;
        [window setFrame: frame display: (sender != nil) animate: (sender != nil)];
        [editAlertControl setNextKeyView: cancelButton];
    }
    if (sender != nil) {
        [[NSUserDefaults standardUserDefaults] setBool: editAlertSelected forKey: PSAlertsEditing];
    }
}


- (IBAction)playSoundChanged:(id)sender;
{
    BOOL playSoundSelected = [playSound intValue];
    BOOL canRepeat = playSoundSelected ? [sound canRepeat] : NO;
    [sound setEnabled: playSoundSelected];
    [soundRepetitions setEnabled: canRepeat];
    [soundRepetitionStepper setEnabled: canRepeat];
    [soundRepetitionsLabel setTextColor: canRepeat ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
    if (playSoundSelected && sender == playSound) {
        [[self window] makeFirstResponder: sound];
    }
}

- (IBAction)setSoundRepetitionCount:(id)sender;
{
    NSTextView *fieldEditor = (NSTextView *)[soundRepetitions currentEditor];
    BOOL isEditing = (fieldEditor != nil);
    int newReps = [sender intValue], oldReps;
    if (isEditing) {
        // XXX work around bug where if you ask soundRepetitions for its intValue too often while it's editing, the field begins to flash
        oldReps = [[[fieldEditor textStorage] string] intValue];
    } else oldReps = [soundRepetitions intValue];
    if (newReps != oldReps) {
        [soundRepetitions setIntValue: newReps];
        // NSLog(@"updating: new value %d, old value %d%@", newReps, oldReps, isEditing ? @", is editing" : @"");
        // XXX work around 10.1 bug, otherwise field only displays every second value
        if (isEditing) [soundRepetitions selectText: self];
    }
}

// XXX should check the 'Do script:' button when someone drops a script on the button

- (IBAction)doScriptChanged:(id)sender;
{
    BOOL doScriptSelected = [doScript intValue];
    [script setEnabled: doScriptSelected];
    [scriptSelectButton setEnabled: doScriptSelected];
    if (doScriptSelected && sender != nil) {
        [[self window] makeFirstResponder: scriptSelectButton];
        if ([script alias] == nil) [scriptSelectButton performClick: sender];
    }
}

- (IBAction)doSpeakChanged:(id)sender;
{
    BOOL doSpeakSelected = [doSpeak state] == NSOnState;
    [voice setEnabled: doSpeakSelected];
    if (doSpeakSelected && sender != nil)
        [[self window] makeFirstResponder: voice];
}

- (void)_readAlerts:(PSAlerts *)alerts;
{
    NSEnumerator *e = [alerts alertEnumerator];
    PSAlert *alert;
    
    [alarm setAlerts: alerts];

    // turn off all alerts
    [bounceDockIcon setState: NSOffState];
    [doScript setIntValue: NO];
    [displayMessage setIntValue: NO];
    [playSound setIntValue: NO];
    [doSpeak setIntValue: NO];

    while ( (alert = [e nextObject]) != nil) {
        if ([alert isKindOfClass: [PSDockBounceAlert class]]) {
            [bounceDockIcon setState: NSOnState];
        } else if ([alert isKindOfClass: [PSScriptAlert class]]) {
            [doScript setIntValue: YES];
            [script setAlias: [(PSScriptAlert *)alert scriptFileAlias]];
        } else if ([alert isKindOfClass: [PSNotifierAlert class]]) {
            [displayMessage setIntValue: YES];
        } else if ([alert isKindOfClass: [PSBeepAlert class]]) {
            unsigned int repetitions = [(PSBeepAlert *)alert repetitions];
            [playSound setIntValue: YES];
            [sound setAlias: nil];
            [soundRepetitions setIntValue: repetitions];
            [soundRepetitionStepper setIntValue: repetitions];
        } else if ([alert isKindOfClass: [PSMovieAlert class]]) {
            unsigned int repetitions = [(PSMovieAlert *)alert repetitions];
            [playSound setIntValue: YES];
            [sound setAlias: [(PSMovieAlert *)alert movieFileAlias]];
            [soundRepetitions setIntValue: repetitions];
            [soundRepetitionStepper setIntValue: repetitions];
        } else if ([alert isKindOfClass: [PSSpeechAlert class]]) {
            [doSpeak setIntValue: YES];
            [voice setVoice: [(PSSpeechAlert *)alert voice]];
        } else if ([alert isKindOfClass: [PSWakeAlert class]]) {
            [wakeUp setIntValue: YES];
        }
}
}

- (BOOL)_setAlerts;
{
    PSAlerts *alerts = [alarm alerts];
    
    [alerts removeAlerts];
    NS_DURING
        // dock bounce alert
        if ([bounceDockIcon state] == NSOnState)
            [alerts addAlert: [PSDockBounceAlert alert]];
        // script alert
        if ([doScript intValue]) {
            BDAlias *scriptFileAlias = [script alias];
            if (scriptFileAlias == nil) {
                [self setStatus: @"Unable to set script alert (no script specified?)"];
                return NO;
            }
            [alerts addAlert: [PSScriptAlert alertWithScriptFileAlias: scriptFileAlias]];
        }
        // notifier alert
        if ([displayMessage intValue])
            [alerts addAlert: [PSNotifierAlert alert]];
        // sound alerts
        if ([playSound intValue]) {
            BDAlias *soundAlias = [sound selectedAlias];
            unsigned short numReps = [soundRepetitions intValue];
            if (soundAlias == nil) // beep alert
                [alerts addAlert: [PSBeepAlert alertWithRepetitions: numReps]];
            else // movie alert
                [alerts addAlert: [PSMovieAlert alertWithMovieFileAlias: soundAlias repetitions: numReps]];
        }
        // speech alert
        if ([doSpeak intValue])
            [alerts addAlert: [PSSpeechAlert alertWithVoice: [voice titleOfSelectedItem]]];
        // wake alert
        if ([wakeUp intValue])
            [alerts addAlert: [PSWakeAlert alert]];
        [[NSUserDefaults standardUserDefaults] setObject: [alerts propertyListRepresentation] forKey: PSAlertsSelected];
    NS_HANDLER
        [self setStatus: [localException reason]];
        NS_VALUERETURN(NO, BOOL);
    NS_ENDHANDLER
    return YES;
}

#pragma mark actions

// to ensure proper updating of interval, this should be the only method by which the window is shown (e.g. from the Alarm menu)
- (IBAction)showWindow:(id)sender;
{
    if (![[self window] isVisible]) {
        NSDate *today = [NSCalendarDate dateForDay: [NSDate date]];
        if ([(NSDate *)[timeDate objectValue] compare: today] == NSOrderedAscending) {
            [timeDate setObjectValue: today];
        }
        [self update: self];
        // XXX bug workaround - otherwise, first responder appears to alternate every time the window is shown.  And if you set the initial first responder, you can't tab in the window. :(
        [[self window] makeFirstResponder: [[self window] initialFirstResponder]];
    }
    [super showWindow: sender];
}

- (IBAction)setAlarm:(NSButton *)sender;
{
    // set alerts before setting alarm...
    if (![self _setAlerts]) return;

    // set alarm
    [self setAlarmDateAndInterval: sender];
    [alarm setRepeating: [timeIntervalRepeats state] == NSOnState];
    [alarm setMessage: [messageField stringValue]];
    if (![alarm setTimer]) {
        [self setStatus: [@"Unable to set alarm.  " stringByAppendingString: [alarm invalidMessage]]];
        return;
    }
    
    [self setStatus: [[alarm date] descriptionWithCalendarFormat: @"Alarm set for %x at %X" timeZone: nil locale: nil]];
    [[self window] close];
    [alarm release];
    alarm = [[PSAlarm alloc] init];
}

- (IBAction)silence:(id)sender;
{
    [sound stopSoundPreview: self];
    [voice stopVoicePreview: self];
}

@end

@implementation PSAlarmSetController (NSControlSubclassDelegate)

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error;
{
    if (control == timeInterval)
        [timeInterval handleDidFailToFormatString: string errorDescription: error label: @"alarm interval"];
    return NO;
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error;
{
    // NSLog(@"UPDATING FROM validation");
    if (control == timeInterval) [self update: timeInterval]; // make sure we still examine the field editor, otherwise if the existing numeric string is invalid, it'll be cleared
}

@end

@implementation PSAlarmSetController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    // NSLog(@"stopping update timer");
    [self silence: nil];
    [self _stopUpdateTimer];
    [self _setAlerts];
}

@end

@implementation PSAlarmSetController (NSControlSubclassNotifications)

// called because we're the delegate

- (void)controlTextDidChange:(NSNotification *)notification;
{
    // NSLog(@"UPDATING FROM controlTextDidChange: %@", [notification object]);
    [self update: [notification object]];
}

@end

@implementation PSAlarmSetController (NJRVoicePopUpButtonDelegate)

- (NSString *)voicePopUpButton:(NJRVoicePopUpButton *)sender previewStringForVoice:(NSString *)voice;
{
    NSString *message = [messageField stringValue];
    if (message == nil || [message length] == 0)
        message = [alarm message];
    return message;
}

@end

@implementation PSAlarmSetController (NSApplicationNotifications)

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [self _setAlerts];
}

- (void)applicationWillHide:(NSNotification *)notification;
{
    if ([[self window] isVisible]) {
        [self silence: nil];
        [self _stopUpdateTimer];
    }
}

- (void)applicationDidUnhide:(NSNotification *)notification;
{
    if ([[self window] isVisible]) {
        [self update: self];
    }
}

@end