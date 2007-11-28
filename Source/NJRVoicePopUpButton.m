//
//  NJRVoicePopUpButton.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRVoicePopUpButton.h"

@implementation NJRVoicePopUpButton

- (void)_refreshVoiceList;
{
    NSMenu *menu;
    NSMenuItem *item;
    NSArray *voices = [NSSpeechSynthesizer availableVoices];

    [self removeAllItems];
    menu = [self menu];
    [menu setAutoenablesItems: NO];
    // XXX would be more elegant with surrogate support like my font popup menu
    item = [menu addItemWithTitle: @"«unknown»" action: nil keyEquivalent: @""];
    [item setEnabled: NO];
    [menu addItem: [NSMenuItem separatorItem]];
    if (voices == nil || [voices count] == 0) {
        item = [menu addItemWithTitle: NSLocalizedString(@"Can't locate voices", "Voice popup menu item surrogate for voice list if no voices are found") action: nil keyEquivalent: @""];
        [item setEnabled: NO];
    } else {
        NSEnumerator *e = [voices objectEnumerator];
        NSString *voice;
        while ( (voice = [e nextObject]) != nil) {
            item = [menu addItemWithTitle:
		    [[NSSpeechSynthesizer attributesForVoice: voice] objectForKey: NSVoiceName]
				   action: @selector(_previewVoice) keyEquivalent: @""];
	    [item setRepresentedObject: voice];
            [item setTarget: self];
        }
    }
    if (_speaker == nil)
	[self selectItemAtIndex: [menu indexOfItemWithRepresentedObject: [NSSpeechSynthesizer defaultVoice]]];
}

- (id)initWithFrame:(NSRect)frame;
{
    if ( (self = [super initWithFrame: frame]) != nil) {
        [self _refreshVoiceList];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if ( (self = [super initWithCoder: coder]) != nil) {
        [self _refreshVoiceList];
    }
    return self;
}

- (NSSpeechSynthesizer *)_speaker;
{
    if (_speaker == nil) _speaker = [[NSSpeechSynthesizer alloc] initWithVoice: nil];
    return _speaker;
}

- (void)_invalidateVoiceSelection;
{
    [self _refreshVoiceList];
    [self selectItemAtIndex: 0];
}

- (void)setVoice:(NSString *)voice;
{
    int voiceIdx = [self indexOfItemWithRepresentedObject: voice];
    if (voiceIdx == -1) {
        [self _invalidateVoiceSelection];
    } else {
        [self selectItemAtIndex: voiceIdx];
    }
}

- (void)_previewVoice;
{
    NSString *voice = [[self selectedItem] representedObject];
    NSString *previewString = nil;

    [_speaker stopSpeaking];

    if (![[self _speaker] setVoice: voice]) {
	// XXX localize title
        NSBeginAlertSheet(@"Voice not available", nil, nil, nil, [self window], nil, nil, nil, nil, NSLocalizedString(@"The voice '%@' you selected could not be used.", "Message displayed in alert sheet when -[NSSpeechSynthesizer setVoice:] returns an error"), [self titleOfSelectedItem]);
        [self _invalidateVoiceSelection];
        return;
    }

    if (_delegate != nil && [_delegate respondsToSelector: @selector(voicePopUpButton:previewStringForVoice:)]) {
        previewString = [_delegate voicePopUpButton: self previewStringForVoice: voice];
    }

    if (previewString == nil)
        previewString = [[NSSpeechSynthesizer attributesForVoice: voice] objectForKey: NSVoiceDemoText];

    [_speaker startSpeakingString: previewString];
}

- (void)dealloc;
{
    [_speaker release];
    [super dealloc];
}

- (IBAction)stopVoicePreview:(id)sender;
{
    [_speaker stopSpeaking];
}

- (void)setEnabled:(BOOL)flag;
{
    [super setEnabled: flag];
    if (flag) ; // XXX [self stopVoicePreview: self]; // need to prohibit at startup
    else [self stopVoicePreview: self];
}

- (void)setDelegate:(id)delegate;
{
    _delegate = delegate;
}

- (id)delegate;
{
    return _delegate;
}

@end