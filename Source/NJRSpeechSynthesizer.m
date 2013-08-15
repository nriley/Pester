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

- (void)NJR_tearDownAUPath;
{
    if (graph == NULL)
	return;

    if (speechChannel != NULL) {
	DisposeSpeechChannel(speechChannel);
	speechChannel = NULL;
    }

    AUGraphStop(graph);
    AUGraphUninitialize(graph);
    AUGraphClose(graph);
    graph = NULL;
}

- (BOOL)NJR_setOutputDevice;
{
    AudioDeviceID outputDevice = [[NJRSoundDevice defaultOutputDevice] deviceID];
    OSStatus err = AudioUnitSetProperty(outputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &outputDevice, sizeof(outputDevice));

    return (err == noErr);
}

- (BOOL)NJR_setVoice:(NSString *)voice;
{
    if (voice == nil) return YES;

    const char *voiceName = [[[NSSpeechSynthesizer attributesForVoice: voice] objectForKey: NSVoiceName] UTF8String];
    size_t voiceLength = strlen(voiceName);
    SInt16 voiceCount, voiceIndex;
    VoiceSpec voiceSpec;
    OSStatus err = CountVoices(&voiceCount);
    if (err != noErr) return NO;
    for (voiceIndex = 1 ; voiceIndex <= voiceCount ; voiceIndex++) {
	err = GetIndVoice(voiceIndex, &voiceSpec);
	if (err != noErr) continue;

	VoiceDescription voiceDescription;
	err = GetVoiceDescription(&voiceSpec, &voiceDescription, sizeof(voiceDescription));
	if (err != noErr) continue;

	if (voiceLength == voiceDescription.name[0] && !strncmp(voiceName, (const char *)(voiceDescription.name + 1), voiceLength))
	    goto foundVoice;
    }
    return NO;

foundVoice:
    err = AudioUnitSetProperty(speechUnit, kAudioUnitProperty_Voice, kAudioUnitScope_Global, 0, &voiceSpec, sizeof(voiceSpec));
    if (err != noErr) return NO;

    return YES;
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

    OSStatus err;
    err = NewAUGraph(&graph);
    if (err != noErr) goto fail;

    AudioComponentDescription outputDescription = {
	.componentType = kAudioUnitType_Output,
	.componentSubType = kAudioUnitSubType_HALOutput,
	.componentManufacturer = kAudioUnitManufacturer_Apple
    };
    AUNode outputNode;
    err = AUGraphAddNode(graph, &outputDescription, &outputNode);
    if (err != noErr) goto fail;

    err = AUGraphOpen(graph);
    if (err != noErr) goto fail;

    err = AUGraphNodeInfo(graph, outputNode, NULL, &outputUnit);
    if (err != noErr || outputUnit == NULL) goto fail;

    if (![self NJR_setOutputDevice]) goto fail;

    AudioComponentDescription speechSynthesisDescription = {
	.componentType = kAudioUnitType_Generator,
	.componentSubType = kAudioUnitSubType_SpeechSynthesis,
	.componentManufacturer = kAudioUnitManufacturer_Apple
    };
    AUNode speechNode;
    err = AUGraphAddNode(graph, &speechSynthesisDescription, &speechNode);
    if (err != noErr) goto fail;

    err = AUGraphNodeInfo(graph, speechNode, NULL, &speechUnit);
    if (err != noErr || speechUnit == NULL) goto fail;

    err = AUGraphConnectNodeInput(graph, speechNode, 0, outputNode, 0);
    if (err != noErr) goto fail;

    err = AUGraphInitialize(graph);
    if (err != noErr) goto fail;

    err = AUGraphStart(graph);
    if (err != noErr) goto fail;

    if (![self NJR_setVoice: voice]) goto fail;

    UInt32 speechChannelSize = sizeof(speechChannel);
    err = AudioUnitGetProperty(speechUnit, kAudioUnitProperty_SpeechChannel, kAudioUnitScope_Global, 0, &speechChannel, &speechChannelSize);
    if (err != noErr) goto fail;

    err = SetSpeechInfo(speechChannel, soRefCon, self);
    if (err != noErr) goto fail;

    err = SetSpeechInfo(speechChannel, soSpeechDoneCallBack, speech_done);
    if (err != noErr) goto fail;

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(defaultSoundOutputDeviceChanged:) name: NJRSoundDeviceDefaultOutputDeviceChangedNotification object: nil];

    return self;

fail:
    [self NJR_tearDownAUPath];

    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [self NJR_tearDownAUPath];
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
