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
@class NJRIntervalField;
@class NJRQTMediaPopUpButton;
@class NJRValidatingField;
@class NJRVoicePopUpButton;
@class PSTimeDateEditor;

@interface PSAlarmSetController : NSWindowController <NSUserInterfaceValidations> {
    IBOutlet NSTextField *messageField;
    IBOutlet NSButton *removeMessageButton;
    IBOutlet NSMatrix *inAtMatrix;
    IBOutlet NJRIntervalField *timeInterval;
    IBOutlet NSPopUpButton *timeIntervalUnits;
    IBOutlet NSButton *timeIntervalRepeats;
    IBOutlet NSTextField *timeOfDay;
    IBOutlet NSTextField *timeDate;
    IBOutlet NSPopUpButton *timeDateCompletions; // XXX should go away when bug preventing both formatters and popup menus from existing is fixed
    IBOutlet NSButton *timeCalendarButton;
    IBOutlet NSButton *editAlert;
    IBOutlet NSTextField *alertView;
    IBOutlet NSTabView *alertTabs;
    IBOutlet NSButtonCell *displayMessage;
    IBOutlet NSButtonCell *bounceDockIcon;
    IBOutlet NSButtonCell *playSound;
    IBOutlet NJRQTMediaPopUpButton *sound;
    IBOutlet NSButton *soundVolumeButton;
    IBOutlet NJRValidatingField *soundRepetitions;
    IBOutlet NSStepper *soundRepetitionStepper;
    IBOutlet NSTextField *soundRepetitionsLabel;
    IBOutlet NSButtonCell *doScript;
    IBOutlet NJRFSObjectSelector *script;
    IBOutlet NSButtonCell *doSpeak;
    IBOutlet NJRVoicePopUpButton *voice;
    IBOutlet NSButton *scriptSelectButton;
    IBOutlet NSButtonCell *wakeUp;
    IBOutlet NSButton *notifyWithGrowlButton;
    IBOutlet NSTextField *timeSummary;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *setButton;
    PSTimeDateEditor *timeDateEditor;
    NSString *status;
    NSTimer *updateTimer;
    PSAlarm *alarm;
    BOOL isInterval;
}

- (IBAction)update:(id)sender;
- (IBAction)dateCompleted:(NSPopUpButton *)sender;
- (IBAction)showCalendar:(NSButton *)sender;
- (IBAction)inAtChanged:(id)sender;
- (IBAction)toggleAlertEditor:(id)sender;
- (IBAction)editAlertChanged:(id)sender;
- (IBAction)playSoundChanged:(id)sender;
- (IBAction)showVolume:(NSButton *)sender;
- (IBAction)doScriptChanged:(id)sender;
- (IBAction)doSpeakChanged:(id)sender;
- (IBAction)setAlarm:(NSButton *)sender;
- (IBAction)setSoundRepetitionCount:(id)sender;

- (IBAction)silence:(id)sender;

@end
