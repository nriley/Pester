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
    NSArray *voiceNames = [SUSpeaker voiceNames];

    [self removeAllItems];
    menu = [self menu];
    [menu setAutoenablesItems: NO];
    // XXX would be more elegant with surrogate support like my font popup menu
    item = [menu addItemWithTitle: @"«unknown»" action: nil keyEquivalent: @""];
    [item setEnabled: NO];
    [menu addItem: [NSMenuItem separatorItem]];
    if (voiceNames == nil || [voiceNames count] == 0) {
        item = [menu addItemWithTitle: @"Can’t locate voices" action: nil keyEquivalent: @""];
        [item setEnabled: NO];
    } else {
        NSEnumerator *e = [voiceNames objectEnumerator];
        NSString *voiceName;
        while ( (voiceName = [e nextObject]) != nil) {
            item = [menu addItemWithTitle: voiceName action: @selector(_previewVoice) keyEquivalent: @""];
            [item setTarget: self];
        }
    }
    if (_speaker == nil) [self selectItemWithTitle: [SUSpeaker defaultVoice]];
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

- (SUSpeaker *)_speaker;
{
    if (_speaker == nil) _speaker = [[SUSpeaker alloc] init];
    return _speaker;
}

- (void)_invalidateVoiceSelection;
{
    [self _refreshVoiceList];
    [self selectItemAtIndex: 0];
}

- (void)setVoice:(NSString *)voice;
{
    int voiceIdx = [self indexOfItemWithTitle: voice];
    if (voiceIdx == -1) {
        [self _invalidateVoiceSelection];
    } else {
        [self selectItemAtIndex: voiceIdx];
    }
}

- (void)_previewVoice;
{
    NSString *voiceName = [self titleOfSelectedItem];
    NSString *previewString = nil;
    VoiceSpec voice;
    OSStatus err = noErr;
    VoiceDescription info;
    short voiceIndex = [[SUSpeaker voiceNames] indexOfObject: voiceName] + 1;

    [_speaker stopSpeaking];

    if ( (err = GetIndVoice(voiceIndex, &voice)) != noErr) {
        NSBeginAlertSheet(@"Voice not available", nil, nil, nil, [self window], nil, nil, nil, nil, @"The voice “%@” you selected could not be used.  An error of type %ld occurred while attempting to retrieve voice information.", voiceName, err);
        [self _invalidateVoiceSelection];
        return;
    }

    if (_delegate != nil && [_delegate respondsToSelector: @selector(voicePopUpButton:previewStringForVoice:)]) {
        previewString = [_delegate voicePopUpButton: self previewStringForVoice: voiceName];
    }

    if (previewString == nil) {
        err = GetVoiceDescription(&voice, &info, sizeof(info));
        if (err != noErr || info.comment[0] == 0)
            previewString = voiceName;
        else {
            previewString = (NSString *)CFStringCreateWithPascalString(NULL, info.comment, kCFStringEncodingMacRoman);
            [previewString autorelease];
        }
    }

    [[self _speaker] setVoice: voiceIndex];
    [_speaker speakText: previewString];
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