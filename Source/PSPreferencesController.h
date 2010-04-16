//
//  PSPreferencesController.h
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NJRHotKeyField;

@interface PSPreferencesController : NSWindowController {
    IBOutlet NJRHotKeyField *setAlarmHotKey;
    IBOutlet NSPopUpButton *soundOutputDevice;
    IBOutlet NSTextField *soundOutputDeviceExplanatoryText;
    IBOutlet NSArrayController *soundOutputDevices;
    NSCharacterSet *textRejectSet;
    NSCharacterSet *commandRejectSet;
    NSCharacterSet *commandShiftRejectSet;
    NSCharacterSet *commandOptionRejectSet;
}

+ (void)readPreferences;

- (IBAction)hotKeySet:(NJRHotKeyField *)sender;
- (IBAction)soundOutputDeviceChanged:(id)sender;

- (NSArray *)allSoundOutputDevices;

@end
