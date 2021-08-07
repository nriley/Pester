//
//  PSAlarmSetController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmSetController.h"
#import "PSAlarmAlertController.h"
#import "PSApplication.h"
#import "PSCalendarController.h"
#import "PSPowerManager.h"
#import "PSTimeDateEditor.h"
#import "PSVolumeController.h"
#import "NJRDateFormatter.h"
#import "NJRFSObjectSelector.h"
#import "NJRIntervalField.h"
#import "NJRMediaPopUpButton.h"
#import "NJRValidatingField.h"
#import "NJRVoicePopUpButton.h"
#import "NSString-NJRExtensions.h"
#import "NSAttributedString-NJRExtensions.h"
#import "NSCalendarDate-NJRExtensions.h"
#import "NSPopUpButton-NJRExtensions.h"

#import "PSAlerts.h"
#import "PSDockBounceAlert.h"
#import "PSScriptAlert.h"
#import "PSNotifierAlert.h"
#import "PSBeepAlert.h"
#import "PSMovieAlert.h"
#import "PSSoundAlert.h"
#import "PSSpeechAlert.h"
#import "PSWakeAlert.h"
#import "PSGrowlAlert.h"
#import "PSUserNotificationAlert.h"

// NSUserDefaults keys
static NSString * const PSAlertsSelected = @"Pester alerts selected";
static NSString * const PSAlertsEditing = @"Pester alerts editing";

@interface PSAlarmSetController (Private)

- (void)_readAlerts:(PSAlerts *)alerts;
- (BOOL)_setAlerts;
- (void)_setVolume:(float)volume withPreview:(BOOL)preview;
- (void)_stopUpdateTimer;
- (void)_tryToFocus:(NSView *)view;

@end

@implementation PSAlarmSetController

- (void)awakeFromNib;
{
    alarm = [[PSAlarm alloc] init];
    [[self window] center];

    timeSummary.font = [NSFont monospacedDigitSystemFontOfSize: timeSummary.font.pointSize weight: NSFontWeightRegular];

    timeDateEditor = [[PSTimeDateEditor alloc] initWithTimeField: timeOfDay dateField: timeDate completions: timeDateCompletions controller: self];
    [timeCalendarButton.image setTemplate: YES];
    [self _setVolume: 1.0f withPreview: NO]; // volume default, usually overridden by restored alert info

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [editAlert setState: [defaults boolForKey: PSAlertsEditing]];
    {
        NSDictionary *plAlerts = [defaults dictionaryForKey: PSAlertsSelected];
        __block PSAlerts *alerts = nil;
        if (plAlerts == nil) {
            alerts = [[PSAlerts alloc] initWithPesterVersion1Alerts];
        } else {
            @try {
                JRThrowErr(alerts = [[PSAlerts alloc] initWithPropertyList: plAlerts error: jrErrRef]);
	    } @catch (NSException *e) {
                [[JRErrContext currentContext] popError]; // don't log unhandled error

                NSAlert *alert = [[NSAlert alloc] init];

                alert.alertStyle = NSAlertStyleCritical;
                alert.messageText = @"Unable to restore alerts";
                NSString *informativeText = [NSString stringWithFormat: @"Pester %@ could not restore recent alert information for the Set Alarm window, potentially because you have previously used a newer version of Pester.\n\n%@", NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"], [e reason]];

                [alert addButtonWithTitle: @"Quit"];
                [alert addButtonWithTitle: @"Use Defaults"];

                NSUInteger alertCount = [[alerts allAlerts] count];
                if (alertCount > 0) {
                    informativeText = [informativeText stringByAppendingFormat: @"\n\nClick Use Restored to use the alerts which could be restored:\n%@", [[alerts prettyList] string]];
                    [alert addButtonWithTitle: @"Use Restored"];
                }
                informativeText = [informativeText stringByAppendingString: @"\n\nClick Use Defaults to use the default set of alerts instead.\n\nIf you accidentally opened the wrong version of Pester, click Quit.\n"];

                alert.informativeText = informativeText;

                switch ([alert runModal]) {
                    case NSAlertThirdButtonReturn:
                        [[NSUserDefaults standardUserDefaults] setObject: [alerts propertyListRepresentation] forKey: PSAlertsSelected];
                        break;
                    case NSAlertSecondButtonReturn:
                        [alerts release];
                        alerts = [[PSAlerts alloc] initWithPesterVersion1Alerts];
                        break;
                    default:
                        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
                        exit(0);
                }

                [alert release];
            }
        }
        [self _readAlerts: alerts];
    }
    [self inAtChanged: nil]; // by convention, if sender is nil, we're initializing
    [self playSoundChanged: nil];
    [self doScriptChanged: nil];
    [self doSpeakChanged: nil];
    [self editAlertChanged: nil];
    [script setFileTypes: [NSArray arrayWithObjects: @"applescript", @"script", NSFileTypeForHFSTypeCode('osas'), NSFileTypeForHFSTypeCode('TEXT'), nil]];

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: self selector: @selector(silence:) name: PSAlarmAlertStopNotification object: nil];
    [notificationCenter addObserver: self selector: @selector(playSoundChanged:) name: NJRMediaPopUpButtonMovieChangedNotification object: sound];
    [notificationCenter addObserver: self selector: @selector(applicationWillHide:) name: NSApplicationWillHideNotification object: NSApp];
    [notificationCenter addObserver: self selector: @selector(applicationDidUnhide:) name: NSApplicationDidUnhideNotification object: NSApp];
    [notificationCenter addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: NSApp];

    [voice setDelegate: self]; // XXX why don't we do this in IB?  It should use the accessor...
    [wakeUp setEnabled: [PSPowerManager autoWakeSupported]];
    
    // XXX workaround for 10.1.x and 10.2.x bug which sets the first responder to the wrong field alternately, but it works if I set the initial first responder to nil... go figure.
    NSWindow *window = [self window];
    [window setInitialFirstResponder: nil];
    [window makeKeyAndOrderFront: nil];
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

- (IBAction)updateDateDisplay:(id)sender;
{
    // NSLog(@"updateDateDisplay: %@", sender);
    if (![alarm isValid]) {
	[setButton setEnabled: NO];
	[self setStatus: [alarm invalidMessage]];
	[self _stopUpdateTimer];
	return;
    }
    
    const int day = 60 * 60 * 24;
    NSInteger daysUntilAlarm = [alarm daysFromToday];
    NSString *onString;
    switch (daysUntilAlarm) {
	case 0: onString = @" today,\n"; break;
	case 1: onString = @" tomorrow,\n"; break;
	default: onString = @"\non ";
    }
    
    [self setStatus: [NSString stringWithFormat: @"Alarm will be set for %@%@%@.", [alarm timeString], onString, [alarm dateString]]];
    [setButton setEnabled: YES];
    if (updateTimer == nil || ![updateTimer isValid]) {
	// XXX this logic (and the timer) should really go into PSAlarm, to send notifications for status updates instead.  Timer starts when people are watching, stops when people aren't.
	// NSLog(@"setting timer");
	if (isInterval) {
	    updateTimer = [NSTimer scheduledTimerWithTimeInterval: 1 target: self selector: @selector(updateDateDisplay:) userInfo: nil repeats: YES];
	} else {
	    // XXX time/time zone change
	    NSTimeInterval interval = [alarm interval];
	    if (daysUntilAlarm < 2 && interval > day)
		interval = [[alarm midnightOnDate] timeIntervalSinceNow];
	    updateTimer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(updateDateDisplay:) userInfo: nil repeats: NO];
	}
	[updateTimer retain];
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
    
    if (sender != nil) {
	// XXX validation doesn't work properly for date/time, so we just universally cancel editing now
        if (![[self window] makeFirstResponder: nil] && !isInterval) {
	    // This works fine synchronously only if you're using the keyboard shortcut to switch in/at.  Directly activating the button, a delayed invocation is necessary.
	    NSInvocation *i = [NSInvocation invocationWithMethodSignature:
			       [inAtMatrix methodSignatureForSelector: @selector(selectCellWithTag:)]];
	    NSInteger tag = [old tag];
	    [i setSelector: @selector(selectCellWithTag:)];
	    [i setTarget: inAtMatrix];
	    [i setArgument: &tag atIndex: 2];
	    [NSTimer scheduledTimerWithTimeInterval: 0 invocation: i repeats: NO];
	    return;
	}
    }
    
    [old setKeyEquivalent: [new keyEquivalent]];
    [old setKeyEquivalentModifierMask: [new keyEquivalentModifierMask]];
    [new setKeyEquivalent: @""];
    [new setKeyEquivalentModifierMask: 0];
    [timeInterval setEnabled: isInterval];
    [timeIntervalUnits setEnabled: isInterval];
    [timeIntervalRepeats setEnabled: isInterval];
    [timeOfDay setEnabled: !isInterval];
    [timeDate setEnabled: !isInterval];
    [timeDateCompletions setEnabled: !isInterval && [timeDateCompletions numberOfItems] > 0];
    [timeCalendarButton setEnabled: !isInterval];
    if (sender != nil)
	[self _tryToFocus: isInterval ? timeInterval : timeOfDay];
    if (!isInterval) // need to do this every time the controls are enabled
        [timeOfDay setNextKeyView: timeDate];
    // NSLog(@"UPDATING FROM inAtChanged");
    [self update: nil];
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

#pragma mark volume

- (IBAction)showVolume:(NSButton *)sender;
{
    [PSVolumeController controllerWithVolume: [sound outputVolume] delegate: self];
}

#define VOLUME_IMAGE_INDEX(vol) (vol * 4) - 0.01

- (void)_setVolume:(float)volume withPreview:(BOOL)preview;
{
    float outputVolume = [sound outputVolume];
    short volumeImageIndex = VOLUME_IMAGE_INDEX(volume);

    if (outputVolume > 0 && volumeImageIndex == VOLUME_IMAGE_INDEX(outputVolume)) return;
    NSString *volumeImageName = [NSString stringWithFormat: @"Volume %hd", volumeImageIndex];
    NSImage *volumeImage = [NSImage imageNamed: volumeImageName];
    [volumeImage setTemplate: YES];
    [soundVolumeButton setImage: volumeImage];

    [sound setOutputVolume: volume withPreview: preview];
}

- (void)volumeController:(PSVolumeController *)controller didSetVolume:(float)volume;
{
    [self _setVolume: volume withPreview: YES];
}

- (NSView *)volumeControllerLaunchingView:(PSVolumeController *)controller;
{
    return soundVolumeButton;
}

#pragma mark alert editing

- (IBAction)toggleAlertEditor:(id)sender;
{
    [editAlert performClick: self];
}

- (IBAction)editAlertChanged:(id)sender;
{
    BOOL editAlertSelected = [editAlert state] == NSOnState;
    NSWindow *window = [self window];
    NSRect frame = [window frame];
    if (editAlertSelected) {
        NSSize editWinSize = [window maxSize];
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
            [alertView setStringValue: [NSString stringWithFormat: @"%@\n%@", NSLocalizedString(@"Couldn't process alert information.", "Message shown in collapsed alert area when alert information is invalid or inconsistent (prevents setting alarm)"), status]];
        } else {
            NSAttributedString *string = [[alarm alerts] prettyList];
            if (string == nil) {
                [alertView setStringValue: NSLocalizedString(@"Do nothing. Click the button beside 'Edit' and add an alert.", "Message shown in collapsed alert edit area when no alerts have been specified")];
            } else {
                [alertView setAttributedStringValue: string];
                [self updateDateDisplay: sender];
            }
        }
        if (sender != nil) { // nil == we're initializing, don't mess with focus
            NSResponder *oldResponder = [window firstResponder];
            // make sure focus doesn't get stuck in the edit tab: it is confusing and leaves behind artifacts
            if (oldResponder == editAlert ||
		([oldResponder isKindOfClass: [NSView class]] && [(NSView *)oldResponder isDescendantOf: alertTabs]))
                [window makeFirstResponder: messageField]; // would use editAlert, but can't get it to display anomaly-free.
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
    [soundVolumeButton setEnabled: canRepeat && [sound canAdjustVolume]];
    [soundRepetitionStepper setEnabled: canRepeat];
    [soundRepetitionsLabel setTextColor: canRepeat ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]];
    if (playSoundSelected && sender != nil)
        [self _tryToFocus: sound];
    else
	[self _tryToFocus: sender];
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
        [self _tryToFocus: scriptSelectButton];
        if ([script alias] == nil) [scriptSelectButton performClick: sender];
    } else {
	[self _tryToFocus: sender];
    }
}

- (IBAction)doSpeakChanged:(id)sender;
{
    BOOL doSpeakSelected = [doSpeak state] == NSOnState;
    [voice setEnabled: doSpeakSelected];
    if (doSpeakSelected && sender != nil)
	[self _tryToFocus: voice];
    else
	[self _tryToFocus: sender];
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
            [bounceDockIcon setIntValue: YES]; // temporary for 1.1b8
        } else if ([alert isKindOfClass: [PSScriptAlert class]]) {
            [doScript setIntValue: YES];
            [script setAlias: [(PSScriptAlert *)alert scriptFileAlias]];
        } else if ([alert isKindOfClass: [PSNotifierAlert class]]) {
            [displayMessage setIntValue: YES];
        } else if ([alert isKindOfClass: [PSMediaAlert class]]) {
            unsigned int repetitions = [(PSMediaAlert *)alert repetitions];
            [playSound setIntValue: YES];
            [soundRepetitions setIntValue: repetitions];
            [soundRepetitionStepper setIntValue: repetitions];
            [self _setVolume: [(PSMediaAlert *)alert outputVolume] withPreview: NO];
            if ([alert isKindOfClass: [PSBeepAlert class]]) {
                [sound setAlias: nil];
            } else if ([alert isKindOfClass: [PSSoundAlert class]]) {
                [sound setAlias: [(PSSoundAlert *)alert soundFileAlias]];
            } else if ([alert isKindOfClass: [PSMovieAlert class]]) {
                [sound setAlias: [(PSMovieAlert *)alert movieFileAlias]];
            }
        } else if ([alert isKindOfClass: [PSSpeechAlert class]]) {
            [doSpeak setIntValue: YES];
            [voice setVoice: [(PSSpeechAlert *)alert voice]];
        } else if ([alert isKindOfClass: [PSWakeAlert class]]) {
            [wakeUp setIntValue: YES];
        } else if ([alert isKindOfClass: [PSGrowlAlert class]]) {
	    [notifyButton setIntValue: YES];
	} else if ([alert isKindOfClass: [PSUserNotificationAlert class]]) {
	    [notifyButton setIntValue: YES];
        }
    }
}

- (BOOL)_setAlerts;
{
    PSAlerts *alerts = [alarm alerts];
    
    [alerts removeAlerts];
    @try {
        // dock bounce alert
        if ([bounceDockIcon intValue]) // temporary for 1.1b8
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
            PSMediaAlert *alert;
            if (soundAlias == nil) // beep alert
                alert = [PSBeepAlert alertWithRepetitions: numReps];
            else if ([sound hasVideo]) // movie alert
                alert = [PSMovieAlert alertWithMovieFileAlias: soundAlias repetitions: numReps];
            else // sound alert
                alert = [PSSoundAlert alertWithSoundFileAlias: soundAlias repetitions: numReps];
            [alerts addAlert: alert];
            [alert setOutputVolume: [sound outputVolume]];
        }
        // speech alert
        if ([doSpeak intValue])
            [alerts addAlert: [PSSpeechAlert alertWithVoice: [[voice selectedItem] representedObject]]];
        // wake alert
        if ([wakeUp intValue])
            [alerts addAlert: [PSWakeAlert alert]];
        // notification alerts
	if ([notifyButton intValue]) {
            [alerts addAlert: [PSUserNotificationAlert alert]];
        }
        [[NSUserDefaults standardUserDefaults] setObject: [alerts propertyListRepresentation] forKey: PSAlertsSelected];
    } @catch (NSException *exception) {
	[self setStatus: [exception reason]];
        return NO;
    }
    return YES;
}

- (void)_tryToFocus:(NSView *)view;
{
    if (view != nil && ![view canBecomeKeyView])
	return;
    [[self window] makeFirstResponder: view];
}

#pragma mark actions

// to ensure proper updating of interval, this should be the only method by which the window is shown (e.g. from the Alarm menu)
- (IBAction)showWindow:(id)sender;
{
    NSWindow *window = [self window];
    
    if (![window isVisible]) {
        NSDate *today = [NSCalendarDate dateForDay: [NSDate date]];
        if ([(NSDate *)[timeDate objectValue] compare: today] == NSOrderedAscending) {
            [timeDate setObjectValue: today];
        }
        [self update: self];
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
        [self setStatus: [@"Unable to set alarm. " stringByAppendingString: [alarm invalidMessage]]];
        return;
    }
    
    [self setStatus: [[alarm date] descriptionWithCalendarFormat: @"Alarm set for %x at %X" timeZone: nil locale: nil]];
    [[self window] close];
	[(PSApplication *)NSApp showTimeRemainingForAlarm: alarm];
    [alarm release];
    alarm = [[PSAlarm alloc] init];
}

- (IBAction)silence:(id)sender;
{
    [sound stopSoundPreview: self];
    [voice stopVoicePreview: self];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem;
{
    if ([anItem action] == @selector(toggleAlertEditor:)) {
        if ([NSApp keyWindow] != [self window])
            return NO;
        [(NSMenuItem *)anItem setState: [editAlert intValue] ? NSOnState : NSOffState];
    }
    return YES;
}

@end

@implementation PSAlarmSetController (NSControlSubclassDelegate)

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error;
{
    if (control == timeInterval)
        [timeInterval handleDidFailToFormatString: string errorDescription: error label: @"alarm interval"];
    else if (control == soundRepetitions)
	[soundRepetitions handleDidFailToFormatString: string errorDescription: error label: @"alert repetitions"];
    return NO;
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error;
{
    // NSLog(@"UPDATING FROM validation");
    if (control == timeInterval) [self update: timeInterval]; // make sure we still examine the field editor, otherwise if the existing numeric string is invalid, it'll be cleared
}

- (BOOL)control:(NSControl *)control isValidObject:(id)obj;
{
    if (control == soundRepetitions && obj == nil) {
	[soundRepetitions handleDidFailToFormatString: nil errorDescription: nil label: @"alert repetitions"];
	return NO;
    }

    return YES;
}

@end

@implementation PSAlarmSetController (NSWindowDelegate)

- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client;
{
    if (client == timeDate)
	return [timeDateEditor dateFieldEditor];

    return nil;
}

@end

@implementation PSAlarmSetController (NSWindowNotifications)

- (void)windowDidBecomeKey:(NSNotification *)notification;
{
    // If date is in the past and isn't being edited, use today so alarm setting/auto-tomorrow can work
    if ([timeDate currentEditor] == nil) {
        NSDate *date = [timeDate objectValue], *now = [NSDate date];
        if (date != nil && [[PSAlarm calendar] compareDate: date toDate: now toUnitGranularity: NSCalendarUnitDay] == NSOrderedAscending) {
            [timeDate setObjectValue: now];
            [self update: nil];
        }
    }
}

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

- (void)controlTextDidEndEditing:(NSNotification *)notification;
{
    if ([notification object] != timeOfDay)
	return;
    
    // if date is today and we've picked a time before now, set the date for tomorrow
    NSDate *date = [timeDate objectValue], *time = [timeOfDay objectValue];
    NSDate *dateTime = [NSCalendarDate dateWithDate: date atTime: time];
    if (dateTime == nil)
	return;

    NSCalendar *calendar = [PSAlarm calendar];
    if (![calendar isDateInToday: date])
        return;

    NSDate *now = [NSDate date];
    if ([dateTime compare: now] != NSOrderedAscending)
        return;

    [timeDate setObjectValue: [calendar dateByAddingUnit: NSCalendarUnitDay value: 1 toDate: now options: NSCalendarMatchFirst]];
    [self update: timeOfDay];
}

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
