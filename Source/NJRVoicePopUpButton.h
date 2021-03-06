//
//  NJRVoicePopUpButton.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NJRSpeechSynthesizer.h"

@interface NJRVoicePopUpButton : NSPopUpButton {
    id _delegate;
    NJRSpeechSynthesizer *_speaker;
    BOOL registeredForVoiceChangedNotification;
}

- (void)setVoice:(NSString *)voice;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (IBAction)stopVoicePreview:(id)sender;

@end

@interface NSObject (NJRVoicePopUpButtonDelegate)

- (NSString *)voicePopUpButton:(NJRVoicePopUpButton *)sender previewStringForVoice:(NSString *)voice;

@end