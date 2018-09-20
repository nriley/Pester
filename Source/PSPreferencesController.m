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

    // migrate from 1.1b8
    NSValue *waitForIdle = [defaults objectForKey: @"PesterAlarmNotifierWaitForIdle"];
    if (waitForIdle != nil) {
	[defaults setObject: waitForIdle forKey: @"PesterAlarmAlertWaitForIdle"];
	[defaults removeObjectForKey: @"PesterAlarmNotifierWaitForIdle"];
	[defaults synchronize];
    }

    NJRHotKeyManager *hotKeyManager = [NJRHotKeyManager sharedManager];
    NJRHotKey *hotKey = [[[NJRHotKey alloc] initWithPropertyList: [defaults dictionaryForKey: PSSetAlarmHotKey]] autorelease];

    [hotKeyManager removeShortcutWithIdentifier: PSSetAlarmHotKeyShortcut];
    if (hotKey != nil) {
        if (![hotKeyManager addShortcutWithIdentifier: PSSetAlarmHotKeyShortcut
                                               hotKey: hotKey
                                               target: NSApp
                                               action: @selector(orderFrontSetAlarmPanelIfPreferencesNotKey:)]) {
            [defaults removeObjectForKey: PSSetAlarmHotKey];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = NSLocalizedString(@"Can't reserve alarm key equivalent", "Hot key set failure");
                alert.informativeText = [NSString stringWithFormat: NSLocalizedString(@"Pester was unable to reserve the key equivalent %@. Please select another in Pester's Preferences, or click Clear to remove it.", "Hot key set failure"), [hotKey keyGlyphs]];
                [alert runModal];
                [(PSApplication *)NSApp orderFrontPreferencesPanel: self];
            });
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
    [self readOutputDeviceFromPrefs];
}

#pragma mark sound output devices

- (NSArray *)allSoundOutputDevices;
{
    return [NJRSoundDevice allOutputDevices];
}

#pragma mark preferences I/O

- (void)readOutputDeviceFromPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NJRSoundDevice *outputDevice = [NJRSoundDevice setDefaultOutputDeviceByUID: [defaults objectForKey: PSSoundOutputDevice]];
    if (outputDevice == nil)
        return;
    [soundOutputDevices setSelectedObjects: [NSArray arrayWithObject: outputDevice]];
}

- (void)readFromPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NJRHotKey *hotKey = [[NJRHotKey alloc] initWithPropertyList: [defaults dictionaryForKey: PSSetAlarmHotKey]];
    [setAlarmHotKey setHotKey: hotKey];
    [hotKey release];

    [self readOutputDeviceFromPrefs];
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
         NSLocalizedString(@"Alert sounds are always played through the default alert device.", "'Play sound through' preference explanatory text")];

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

    if (modifierFlags == 0 || modifierFlags == NSShiftKeyMask || modifierFlags == NSEventModifierFlagOption || modifierFlags == (NSShiftKeyMask | NSEventModifierFlagOption)) {
        *message = modifierFlags == 0 ? @"key is reserved for typing text" :
                                        @"key combination is reserved for typing text";
        return ![textRejectSet characterIsMember: keyChar];
    }
    if (modifierFlags == NSCommandKeyMask) {
        *message = @"key combination is reserved for application use";
        return ![commandRejectSet characterIsMember: keyChar];
    }
    if (modifierFlags == (NSEventModifierFlagCommand | NSShiftKeyMask)) {
        *message = @"key combination is reserved for application use";
        return ![commandShiftRejectSet characterIsMember: keyChar];
    }
    if (modifierFlags == (NSCommandKeyMask | NSEventModifierFlagOption)) {
        *message = @"key combination is reserved for Mac OS X use";
        return ![commandOptionRejectSet characterIsMember: keyChar];
    }
    return YES;
}

@end
