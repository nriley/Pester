//
//  PSPreferencesController.m
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSPreferencesController.h"
#import "NJRHotKeyField.h"

@implementation PSPreferencesController

#pragma mark interface updating

- (void)update;
{
    // perform any interface propagation that needs to be done
}

#pragma mark preferences I/O

- (void)readFromPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [setAlarmHotKey setFromPropertyList: [defaults dictionaryForKey: @"Pester set alarm system-wide keyboard shortcut"]];
}

- (void)writeToPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [setAlarmHotKey propertyListRepresentation] forKey: @"Pester set alarm system-wide keyboard shortcut"];
    [defaults synchronize];
}

#pragma mark initialize-release

- (id)init {
    if ( (self = [super initWithWindowNibName: @"Preferences"]) != nil) {
        [self window]; // connect outlets
        [self readFromPrefs];
        [self update];
        // command
        NSMutableCharacterSet *set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [set addCharactersInString: @"`-=[]/\\ "];
        commandRejectSet = [set copy];
        [set release];
        // no modifiers, shift, option, option-shift
        set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [set formUnionWithCharacterSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [set formUnionWithCharacterSet: [NSCharacterSet punctuationCharacterSet]];
        [set addCharactersInString: @"\t\r\e\x7f\x03\x19"]; // tab, CR, escape, delete, enter, backtab
        [set addCharactersInRange: NSMakeRange(0xF700, 0x1FF)]; // reserved function key range
        [set removeCharactersInRange: NSMakeRange(NSF1FunctionKey, 15)]; // F1-F15
        textRejectSet = [set copy];
        [set release];
        // command-shift
        commandShiftRejectSet = [[NSCharacterSet characterSetWithCharactersInString: @"ACFGHIPQS~? "] retain];
        // command-option
        commandOptionRejectSet = [[NSCharacterSet characterSetWithCharactersInString: @"DW\\-= "] retain];
    }
    return self;
}

- (void)dealloc;
{
    [textRejectSet release];
    [commandRejectSet release];
    [commandShiftRejectSet release];
    [commandOptionRejectSet release];
}

#pragma mark actions

- (IBAction)hotKeySet:(NJRHotKeyField *)sender;
{
    [self writeToPrefs];
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
