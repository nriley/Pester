//
//  NJRVoicePopUpButton.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SUSpeaker.h"

@interface NJRVoicePopUpButton : NSPopUpButton {
    id _delegate;
    SUSpeaker *_speaker;
}

- (void)setDelegate:(id)delegate;
- (id)delegate;

- (IBAction)stopVoicePreview:(id)sender;

@end

@interface NSObject (NJRVoicePopUpButtonDelegate)

- (NSString *)voicePopUpButton:(NJRVoicePopUpButton *)sender previewStringForVoice:(NSString *)voice;

@end