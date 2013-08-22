//
//  PSPreferencesController.m
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSPreferencesController.h"
#import "PSApplication.h"
#import "NJRArrayToObjectTransformer.h"
#import "NJRHotKeyField.h"
#import "NJRHotKey.h"
#import "NJRHotKeyManager.h"
#import "NJRSoundDevice.h"

// NSUserDefaults keys
static NSString * const PSSetAlarmHotKey = @"Pester set alarm system-wide keyboard shortcut";
static NSString * const PSSoundOutputDevice = @"Pester sound output device";

// NJRHotKeyManager shortcut identifier
static NSString * const PSSetAlarmHotKeyShortcut = @"PSSetAlarmHotKeyShortcut";

@interface PSPreferencesController ()
- (void)soundOutputDeviceListChanged:(NSNotification *)notification;
@end

@implementation PSPreferencesController

+ (void)readPreferences;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NJRHotKeyManager *hotKeyManager = [NJRHotKeyManager sharedManager];
    NJRHotKey *hotKey = [[[NJRHotKey alloc] initWithPropertyList: [defaults dictionaryForKey: PSSetAlarmHotKey]] autorelease];

    // migrate from 1.1b8
    NSValue *waitForIdle = [defaults objectForKey: @"PesterAlarmNotifierWaitForIdle"];
    if (waitForIdle != nil) {
	[defaults setObject: waitForIdle forKey: @"PesterAlarmAlertWaitForIdle"];
	[defaults removeObjectForKey: @"PesterAlarmNotifierWaitForIdle"];
	[defaults synchronize];
    }

    if (hotKey == nil) {
        [hotKeyManager removeShortcutWithIdentifier: PSSetAlarmHotKeyShortcut];
    } else {
        if (![hotKeyManager addShortcutWithIdentifier: PSSetAlarmHotKeyShortcut
                                               hotKey: hotKey
                                               target: NSApp
                                               action: @selector(orderFrontSetAlarmPanelIfPreferencesNotKey:)]) {
            [defaults removeObjectForKey: PSSetAlarmHotKey];
            NSRunAlertPanel(NSLocalizedString(@"Can't reserve alarm key equivalent", "Hot key set failure"),
                            NSLocalizedString(@"Pester was unable to reserve the key equivalent %@. Please select another in Pester's Preferences, or click Clear to remove it.", "Hot key set failure"), nil, nil, nil, [hotKey keyGlyphs]);
            [(PSApplication *)NSApp performSelector: @selector(orderFrontPreferencesPanel:) withObject: self afterDelay: 0.1];
        }
    }

    [NJRSoundDevice setDefaultOutputDeviceByUID: [defaults objectForKey: PSSoundOutputDevice]];
}

#pragma mark interface updating

- (void)update;
{
    // perform any interface propagation that needs to be done
}

- (void)soundOutputDeviceListChanged:(NSNotification *)notification;
{
    [soundOutputDevices setContent: [notification object]];
}

#pragma mark sound output devices

- (NSArray *)allSoundOutputDevices;
{
    return [NJRSoundDevice allOutputDevices];
}

#pragma mark preferences I/O

- (void)readFromPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NJRHotKey *hotKey = [[NJRHotKey alloc] initWithPropertyList: [defaults dictionaryForKey: PSSetAlarmHotKey]];
    [setAlarmHotKey setHotKey: hotKey];
    [hotKey release];

    NJRSoundDevice *outputDevice = [NJRSoundDevice setDefaultOutputDeviceByUID: [defaults objectForKey: PSSoundOutputDevice]];
    if (outputDevice == nil)
	return;
    [soundOutputDevices setSelectedObjects: [NSArray arrayWithObject: outputDevice]];
}

- (void)writeToPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [[setAlarmHotKey hotKey] propertyListRepresentation] forKey: PSSetAlarmHotKey];
    [defaults setObject: [[[soundOutputDevice selectedItem] representedObject] uid] forKey: PSSoundOutputDevice];

    [defaults synchronize];
    [[self class] readPreferences];
}

#pragma mark initialize-release

- (id)init {
	// XXX Register controller for 10.4.  This is not necessary on 10.5 and later.
	NSValueTransformer *transformer = [[NJRArrayToObjectTransformer alloc] init];
	[NSValueTransformer setValueTransformer: transformer forName: @"NJRArrayToObjectTransformer"];
    [transformer release];

    if ( (self = [super initWithWindowNibName: @"Preferences"]) != nil) {
        [[self window] center]; // connect outlets
        [self readFromPrefs];
        [self update];
        // command
        NSMutableCharacterSet *set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [set addCharactersInString: @"`-=[]/\\, "];
        commandRejectSet = [set copy];
        [set release];
        // no modifiers, shift, option, option-shift
        set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [set formUnionWithCharacterSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [set formUnionWithCharacterSet: [NSCharacterSet punctuationCharacterSet]];
        [set formUnionWithCharacterSet: [NSCharacterSet symbolCharacterSet]];
        [set addCharactersInString: @"\r\e\x7f\x03"]; // CR, escape, delete, enter
        [set addCharactersInRange: NSMakeRange(0xF700, 0x1FF)]; // reserved function key range
        [set removeCharactersInRange: NSMakeRange(NSF1FunctionKey, 15)]; // F1-F15
        textRejectSet = [set copy];
        [set release];
        // command-shift
        commandShiftRejectSet = [[NSCharacterSet characterSetWithCharactersInString: @"ACFGHIPQS~? "] retain];
        // command-option
        commandOptionRejectSet = [[NSCharacterSet characterSetWithCharactersInString: @"DW\\-= "] retain];

        [soundOutputDeviceExplanatoryText setStringValue:
         NSLocalizedString(@"Alert sounds are always played through the default alert device.", "'Play sound through' preference explanatory text for 10.5+")];

        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(soundOutputDeviceListChanged:) name: NJRSoundDeviceListChangedNotification object: nil];
    }
    return self;
}

- (void)dealloc;
{
    [textRejectSet release];
    [commandRejectSet release];
    [commandShiftRejectSet release];
    [commandOptionRejectSet release];
    [super dealloc];
}

#pragma mark actions

- (IBAction)hotKeySet:(NJRHotKeyField *)sender;
{
    [self writeToPrefs];
}

- (IBAction)soundOutputDeviceChanged:(id)sender;
{
    [self writeToPrefs];
}

- (IBAction)showWindow:(id)sender;
{
    [self readFromPrefs];
    [super showWindow: sender];
}

@end

@implementation PSPreferencesController (NJRHotKeyFieldDelegate)

- (BOOL)hotKeyField:(NJRHotKeyField *)hotKeyField shouldAcceptCharacter:(unichar)keyChar modifierFlags:(unsigned)modifierFlags rejectionMessage:(NSString **)message;
{
    *message = nil;

    if (modifierFlags == 0 || modifierFlags == NSShiftKeyMask || modifierFlags == NSAlternateKeyMask || modifierFlags == (NSShiftKeyMask | NSAlternateKeyMask)) {
        *message = modifierFlags == 0 ? @"key is reserved for typing text" :
                                        @"key combination is reserved for typing text";
        return ![textRejectSet characterIsMember: keyChar];
    }
    if (modifierFlags == NSCommandKeyMask) {
        *message = @"key combination is reserved for application use";
        return ![commandRejectSet characterIsMember: keyChar];
    }
    if (modifierFlags == (NSCommandKeyMask | NSShiftKeyMask)) {
        *message = @"key combination is reserved for application use";
        return ![commandShiftRejectSet characterIsMember: keyChar];
    }
    if (modifierFlags == (NSCommandKeyMask | NSAlternateKeyMask)) {
        *message = @"key combination is reserved for Mac OS X use";
        return ![commandOptionRejectSet characterIsMember: keyChar];
    }
    return YES;
}

@end
