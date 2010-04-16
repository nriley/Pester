//
//  PSSpeechAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlert.h"
#import "NJRSpeechSynthesizer.h"

@interface PSSpeechAlert : PSAlert {
    NJRSpeechSynthesizer *speaker;
    NSString *voice;
    PSAlarm *alarm;
}

+ (PSSpeechAlert *)alertWithVoice:(NSString *)aVoice;

- (id)initWithVoice:(NSString *)aVoice;

- (NSString *)voice;

@end
