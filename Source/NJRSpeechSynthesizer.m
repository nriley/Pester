//
//  NJRSpeechSynthesizer.m
//  Pester
//
//  Created by Nicholas Riley on 4/15/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "NJRSpeechSynthesizer.h"
#import "NJRSoundDevice.h"

@implementation NJRSpeechSynthesizer

- (void)NJR_tearDownSpeechChannel;
{
    if (speechChannel != NULL) {
	DisposeSpeechChannel(speechChannel);
	speechChannel = NULL;
    }
}

- (BOOL)NJR_setOutputDevice;
{
    if (speechChannel == NULL)
        return NO;

    AudioDeviceID outputDevice = [[NJRSoundDevice defaultOutputDevice] deviceID];
    OSStatus err = SetSpeechInfo(speechChannel, soOutputToAudioDevice, &outputDevice);

    return (err == noErr);
}

static BOOL voiceSpecForVoice(NSString *voice, VoiceSpec *voiceSpec) {
    if (voice == nil)
        return NO;

    const char *voiceName = [[[NSSpeechSynthesizer attributesForVoice: voice] objectForKey: NSVoiceName] UTF8String];
    size_t voiceLength = strlen(voiceName);
    SInt16 voiceCount, voiceIndex;
    OSStatus err = CountVoices(&voiceCount);
    if (err != noErr) return NO;
    for (voiceIndex = 1 ; voiceIndex <= voiceCount ; voiceIndex++) {
        err = GetIndVoice(voiceIndex, voiceSpec);
        if (err != noErr) continue;

        VoiceDescription voiceDescription;
        err = GetVoiceDescription(voiceSpec, &voiceDescription, sizeof(voiceDescription));
        if (err != noErr) continue;

        if (voiceLength == voiceDescription.name[0] && !strncmp(voiceName, (const char *)(voiceDescription.name + 1), voiceLength))
            return YES;
    }
    return NO;
}

- (BOOL)NJR_setVoice:(NSString *)voice;
{
    // We can't change the voice without recreating the speech channel in the general case.
    // Changing voices did work with the AU-based path in 10.6, but broke in (at least) 10.8.
    // http://lists.apple.com/archives/speech-dev/2013/Jan/msg00002.html

    [self NJR_tearDownSpeechChannel];

    VoiceSpec voiceSpec;
    BOOL haveVoiceSpec = voiceSpecForVoice(voice, &voiceSpec);

    OSStatus err;
    err = NewSpeechChannel(haveVoiceSpec ? &voiceSpec : NULL, &speechChannel);
    if (err != noErr) goto fail;

    if (![self NJR_setOutputDevice]) goto fail;

    err = SetSpeechInfo(speechChannel, soRefCon, self);
    if (err != noErr) goto fail;

    err = SetSpeechInfo(speechChannel, soSpeechDoneCallBack, speech_done);
    if (err != noErr) goto fail;

    return YES;

fail:
    [self NJR_tearDownSpeechChannel];

    return NO;

}

static void speech_done(SpeechChannel speechChannel, long /*SRefCon*/ refCon) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NJRSpeechSynthesizer *synthesizer = (NJRSpeechSynthesizer *)refCon;
    id delegate = [synthesizer delegate];
    if (delegate == nil)
	return;

    SEL selector = @selector(speechSynthesizer:didFinishSpeaking:);
    NSInvocation *invocation =
	[NSInvocation invocationWithMethodSignature:
	 [delegate methodSignatureForSelector: selector]];
    [invocation setSelector: selector];
    BOOL yes = YES;
    [invocation setArgument: &yes atIndex: 3];
    [invocation performSelectorOnMainThread: @selector(invokeWithTarget:) withObject: delegate waitUntilDone: NO];
    [pool release];
}

- (id)initWithVoice:(NSString *)voice;
{
    if ( (self = [super initWithVoice: voice]) == nil) return nil;

    [self NJR_setVoice: voice];

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(defaultSoundOutputDeviceChanged:) name: NJRSoundDeviceDefaultOutputDeviceChangedNotification object: nil];

    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self NJR_tearDownSpeechChannel];
    [super dealloc];
}

- (BOOL)setVoice:(NSString *)voice;
{
    if (speechChannel != NULL)
	return [self NJR_setVoice: voice];

    return [super setVoice: voice];
}

- (BOOL)startSpeakingString:(NSString *)string;
{
    if (speechChannel != NULL && SpeakCFString(speechChannel, (CFStringRef)string, NULL) == noErr)
	return YES;

    return [super startSpeakingString: string];
}

- (void)stopSpeaking;
{
    if (speechChannel == NULL)
	return;

    StopSpeech(speechChannel);
}

- (void)defaultSoundOutputDeviceChanged:(NSNotification *)notification;
{
    [self NJR_setOutputDevice];
}

@end
