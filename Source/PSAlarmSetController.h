//
//  PSAlarmSetController.h
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSAlarm.h"

@class NJRFSObjectSelector;
@class NJRQTMediaPopUpButton;
@class NJRVoicePopUpButton;

@interface PSAlarmSetController : NSWindowController {
    IBOutlet NSTextField *messageField;
    IBOutlet NSMatrix *inAtMatrix;
    IBOutlet NSTextField *timeInterval;
    IBOutlet NSPopUpButton *timeIntervalUnits;
    IBOutlet NSButton *timeIntervalRepeats;
    IBOutlet NSTextField *timeOfDay;
    IBOutlet NSTextField *timeDate;
    IBOutlet NSPopUpButton *timeDateCompletions; // XXX should go away when bug preventing both formatters and popup menus from existing is fixed
    IBOutlet NSButtonCell *displayMessage;
    IBOutlet NSButton *bounceDockIcon;
    IBOutlet NSButtonCell *playSound;
    IBOutlet NJRQTMediaPopUpButton *sound;
    IBOutlet NSTextField *soundRepetitions;
    IBOutlet NSStepper *soundRepetitionStepper;
    IBOutlet NSTextField *soundRepetitionsLabel;
    IBOutlet NSButtonCell *doScript;
    IBOutlet NJRFSObjectSelector *script;
    IBOutlet NSButtonCell *doSpeak;
    IBOutlet NJRVoicePopUpButton *voice;
    IBOutlet NSButton *scriptSelectButton;
    IBOutlet NSTextField *timeSummary;
    IBOutlet NSButton *setButton;
    NSString *status;
    NSTimer *updateTimer;
    PSAlarm *alarm;
    BOOL isInterval;
}

- (IBAction)update:(id)sender;
- (IBAction)dateCompleted:(NSPopUpButton *)sender;
- (IBAction)inAtChanged:(id)sender;
- (IBAction)playSoundChanged:(id)sender;
- (IBAction)doScriptChanged:(id)sender;
- (IBAction)doSpeakChanged:(id)sender;
- (IBAction)setAlarm:(NSButton *)sender;

- (IBAction)silence:(id)sender;

@end
