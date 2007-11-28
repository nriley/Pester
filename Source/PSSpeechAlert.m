//
//  PSSpeechAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSSpeechAlert.h"
#import "PSAlarmAlertController.h"
#import "NSDictionary-NJRExtensions.h"

// property list keys
static NSString * const PLAlertVoice = @"voice"; // NSString

@implementation PSSpeechAlert

+ (PSSpeechAlert *)alertWithVoice:(NSString *)aVoice;
{
    return [[[self alloc] initWithVoice: aVoice] autorelease];
}

- (id)initWithVoice:(NSString *)aVoice;
{
    if ( (self = [super init]) != nil) {
        voice = [aVoice retain];
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

- (NSString *)voice;
{
    return voice;
}

- (void)_stopSpeaking:(NSNotification *)notification;
{
    [speaker stopSpeaking]; // triggers didFinishSpeaking:
}

- (void)triggerForAlarm:(PSAlarm *)anAlarm;
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopSpeaking:) name: PSAlarmAlertStopNotification object: nil];
    
    if ( (speaker = [[NSSpeechSynthesizer alloc] initWithVoice: voice]) == nil) return;
    alarm = anAlarm;
    [speaker setDelegate: self];
    [speaker startSpeakingString: [alarm message]];
}

- (NSAttributedString *)actionDescription;
{
    NSMutableAttributedString *string = [[@"Speak message with voice " small] mutableCopy];
    [string appendAttributedString: [voice underlined]];
    return [string autorelease];
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *plAlert = [[super propertyListRepresentation] mutableCopy];
    if (voice == nil)
	@throw [NSException exceptionWithName: NSInvalidArgumentException
				       reason: @"The selected voice is not available." userInfo: nil];
    [plAlert setObject: voice forKey: PLAlertVoice];
    return [plAlert autorelease];
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self init]) != nil) {
        voice = [[dict objectForRequiredKey: PLAlertVoice] retain];
    }
    return self;
}

@end

@implementation PSSpeechAlert (NSSpeechSynthesizerDelegate)

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking;
{
    [self completedForAlarm: alarm];
    [speaker release]; speaker = nil;
}

@end