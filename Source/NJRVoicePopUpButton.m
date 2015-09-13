//
//  NJRVoicePopUpButton.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRVoicePopUpButton.h"

@interface NJRVoicePopUpButton (Private)
- (void)_previewVoice;
@end

// XXX unaware of any public way to get enabled voice information; this is reverse-engineered
// Voices enabled by default do not have VoiceShowInFullListOnly in their voice attributes.
// Value in visibleIdentifiers is 1 if the voice is visible in the System Voice popup menu.
// Voices disabled by the user are 0; 2 is for voices that have never been disabled or enabled.
typedef NS_ENUM(NSInteger, NJRVoiceVisibility) {
    NJRVoiceDisabled = 0,
    NJRVoiceEnabled = 1,
    NJRVoiceUseDefault = 2
};

@implementation NJRVoicePopUpButton

- (void)_refreshVoiceList;
{
    NSString *selectedVoice = [[self selectedItem] representedObject];
    [self removeAllItems];

    NSMenu *menu = [self menu];
    [menu setAutoenablesItems: NO];

    NSMenuItem *item = [menu addItemWithTitle: @"«unknown»" action: nil keyEquivalent: @""];
    [item setEnabled: NO];
    [item setHidden: YES];

    NSArray *voices = [NSSpeechSynthesizer availableVoices];
    NSString *defaultVoice = [NSSpeechSynthesizer defaultVoice];
    item = nil;

    if (voices != nil) {
        // XXX unaware of any public way to get enabled voice information; this is reverse-engineered
        NSDictionary *visibleIdentifiers = [[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"com.apple.speech.voice.prefs"] objectForKey: @"VisibleIdentifiers"];
        if (visibleIdentifiers != nil && [visibleIdentifiers count] == 0)
            visibleIdentifiers = nil;

        for (NSString *voice in voices) {
            NJRVoiceVisibility visibility = NJRVoiceUseDefault;
            // default voice may be unchecked, but we should show it (so does System Preferences)
            if ([voice isEqualToString: defaultVoice]) {
                visibility = NJRVoiceEnabled;
            } else if (visibleIdentifiers != nil) {
                NSNumber *visibleIdentifier = visibleIdentifiers[voice];
                if (visibleIdentifier == nil)
                    visibleIdentifier = visibleIdentifiers[[voice stringByAppendingString: @".premium"]];
                if (visibleIdentifier == nil)
                    continue;
                visibility = [visibleIdentifier integerValue];
                if (visibility == NJRVoiceDisabled)
                    continue;
            }
            NSDictionary *voiceAttributes = [NSSpeechSynthesizer attributesForVoice: voice];
            if (visibility == NJRVoiceUseDefault) {
                if (voiceAttributes[@"VoiceShowInFullListOnly"] != nil)
                    continue;
            }
            item = [menu addItemWithTitle:
                    voiceAttributes[NSVoiceName]
                                   action: @selector(_previewVoice) keyEquivalent: @""];
            [item setRepresentedObject: voice];
            [item setTarget: self];
            if ([voice isEqualToString: selectedVoice])
                [self selectItem: item];
        }
    }
    if (item == nil) {
        item = [menu addItemWithTitle: NSLocalizedString(@"Can't locate voices", "Voice popup menu item surrogate for voice list if no voices are found") action: nil keyEquivalent: @""];
        [item setEnabled: NO];
    } else if (selectedVoice == nil) {
        [self setVoice: defaultVoice];
    }

    if (!registeredForVoiceChangedNotification) {
        [[NSDistributedNotificationCenter defaultCenter] addObserver: self selector: @selector(_refreshVoiceList) name: @"com.apple.speech.DefaultVoiceChangedNotification" object: nil];
        registeredForVoiceChangedNotification = YES;
    }
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
    if (_speaker == nil) _speaker = [[NJRSpeechSynthesizer alloc] initWithVoice: nil];
    return _speaker;
}

- (void)_invalidateVoiceSelection;
{
    [self _refreshVoiceList];
    [self selectItemAtIndex: 0];
}

- (void)setVoice:(NSString *)voice;
{
    NSInteger voiceIdx = [self indexOfItemWithRepresentedObject: voice];
    if (voiceIdx == -1) {
        [self _invalidateVoiceSelection];
        return;
    }
    [self selectItemAtIndex: voiceIdx];
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
        previewString = [NSSpeechSynthesizer attributesForVoice: voice][NSVoiceDemoText];

    [_speaker startSpeakingString: previewString];
}

- (void)dealloc;
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver: self];
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