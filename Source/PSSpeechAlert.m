//
//  PSSpeechAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "PSSpeechAlert.h"
#import "PSAlarmAlertController.h"

@implementation PSSpeechAlert

+ (PSSpeechAlert *)alertWithVoice:(NSString *)aVoice;
{
    return [[[self alloc] initWithVoice: aVoice] autorelease];
}

- (id)initWithVoice:(NSString *)aVoice;
{
    if ( (self = [super init]) != nil) {
        voice = aVoice;
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [speaker release]; speaker = nil;
    [voice release]; voice = nil;
    [super dealloc];
}

- (void)_stopSpeaking:(NSNotification *)notification;
{
    [speaker stopSpeaking];
    // don't release here, we'll still get the didFinishSpeaking: message as a delegate
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopSpeaking:) name: PSAlarmAlertStopNotification object: nil];
    
    if ( (speaker = [[SUSpeaker alloc] init]) == nil) return;
    [speaker setDelegate: self];
    [speaker setVoice: [[SUSpeaker voiceNames] indexOfObject: voice] + 1];
    [speaker speakText: [alarm message]];
    
    [self retain];
}

@end

@implementation PSSpeechAlert (SUSpeakerDelegate)

- (void)didFinishSpeaking:(SUSpeaker*)speaker;
{
    [self release];
}

@end