//
//  NJRSpeechSynthesizer.h
//  Pester
//
//  Created by Nicholas Riley on 4/15/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <ApplicationServices/ApplicationServices.h>
#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>

@interface NJRSpeechSynthesizer : NSSpeechSynthesizer {
    AUGraph graph;
    AudioUnit outputUnit;
    AudioUnit speechUnit;
    SpeechChannel speechChannel;
}

- (id)initWithVoice:(NSString *)voice;

- (BOOL)startSpeakingString:(NSString *)string;

- (void)stopSpeaking;

@end
