//
//  PSAudioAlert.m
//  Pester
//
//  Created by Nicholas Riley on 9/21/15.
//
//

#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import <mach/mach_time.h>
#import "PSAudioAlert.h"
#import "PSAlarmAlertController.h"
#import "NSDictionary-NJRExtensions.h"
#import "NJRSoundDevice.h"
#import "BDAlias.h"

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSString
static NSString * const PLAlertAlias = @"alias"; // NSData

@implementation PSAudioAlert

+ (PSAudioAlert *)alertWithAudioFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;
{
    return [[[self alloc] initWithAudioFileAlias: anAlias repetitions: numReps] autorelease];
}

- (id)initWithAudioFileAlias:(BDAlias *)anAlias repetitions:(unsigned int)numReps;
{
    if ( (self = [super initWithRepetitions: numReps]) != nil) {
        NSURL *fileURL = [anAlias fileURL];
        if (fileURL == nil) {
            [self release];
            [NSException raise: PSAlertCreationException format: NSLocalizedString(@"Can't locate audio to play as alert.", "Exception message on PSAudioAlert initialization when alias doesn't resolve")];
        }
        alias = [anAlias retain];
        
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading: fileURL error: NULL];
        if (audioFile == nil) { // exists, but we can't play it
            [self release];
            self = nil;
        }
        [audioFile release];
    }
    
    return self;
}

- (BDAlias *)audioFileAlias;
{
    return alias;
}

- (unsigned short)repetitions;
{
    return repetitions;
}

- (void)dealloc;
{
    [alias release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"PSAudioAlert: %@, repeats %hu times%@", [alias fullPath], repetitions, outputVolume != PSMediaAlertNoVolume ? [NSString stringWithFormat: @" at %.0f%% volume", outputVolume * 100] : @""];
}

- (void)_stopPlaying:(NSNotification *)notification;
{
    [audioEngine stop];
    [audioEngine release];
    audioEngine = nil;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NSError *error = nil;
    NSURL *fileURL = [alias fileURL];
    if (fileURL == nil) {
        NSLog(@"PSAudioAlert: can't resolve alias");
        return;
    }
    NSLog(@"%@", fileURL);

    AVAudioFile *file = [[AVAudioFile alloc] initForReading: [alias fileURL] error: &error];
    if (file == nil) {
        NSLog(@"PSAudioAlert: can't init AVAudioFile: %@", error);
        return;
    }
    
    audioEngine = [[AVAudioEngine alloc] init];
    AudioUnit outputUnit = audioEngine.outputNode.audioUnit;
    AudioDeviceID outputDeviceID = [[NJRSoundDevice defaultOutputDevice] deviceID];
    
    OSStatus err = AudioUnitSetProperty(outputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &outputDeviceID, sizeof(outputDeviceID));
    if (err)
        NSLog(@"PSAudioAlert: can't set output device: %d", (int)err);
    
    AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
    [audioEngine attachNode: player];
    [player release];
    [audioEngine connect: player to: audioEngine.outputNode format:nil];
    
    NSLog(@"engine: %@", audioEngine);
    
    if (![audioEngine startAndReturnError: &error]) {
        NSLog(@"PSAudioAlert: can't start engine: %@", error);
        [file release];
        [audioEngine release];
        audioEngine = nil;
        return;
    }
    
    for (NSUInteger repetition = 1 ; repetition < repetitions ; repetition++)
        [player scheduleFile: file atTime: nil completionHandler: ^{
            if (player.playing)
                NSLog(@"playing %d %@", repetition, player.lastRenderTime);
        }];

    [player scheduleFile: file atTime: nil completionHandler: ^{
        if (player.playing)
            NSLog(@"playing last %@", player.lastRenderTime);
        [self _stopPlaying: nil];

        // [engine release];
        // [self release];
    }];

    [file release];
    [player play];

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopPlaying:) name: PSAlarmAlertStopNotification object: nil];
}

- (NSAttributedString *)actionDescription;
{
    NSMutableAttributedString *string = [[@"Play " small] mutableCopy];
    NSString *kindString = nil, *name = [alias displayNameWithKindString: &kindString];
    if (name == nil) name = NSLocalizedString(@"<<can't locate audio file>>", "Audio alert description surrogate for media display name when alias doesn't resolve");
    else [string appendAttributedString: [[NSString stringWithFormat: @"%@ ", kindString] small]];
    [string appendAttributedString: [name underlined]];
    if (repetitions > 1) {
        [string appendAttributedString: [[NSString stringWithFormat: @" %hu times", repetitions] small]];
    }
    if (outputVolume != PSMediaAlertNoVolume) {
        [string appendAttributedString: [[NSString stringWithFormat: @" at %.0f%% volume", outputVolume * 100] small]];
    }
    return [string autorelease];
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableDictionary *plAlert = [[super propertyListRepresentation] mutableCopy];
    [plAlert setObject: [NSNumber numberWithUnsignedShort: repetitions] forKey: PLAlertRepetitions];
    [plAlert setObject: [alias aliasData] forKey: PLAlertAlias];
    return [plAlert autorelease];
}

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    if ( (self = [super initWithPropertyList: dict error: error]) != nil)
        [self initWithAudioFileAlias: [BDAlias aliasWithData: [dict objectForRequiredKey: PLAlertAlias]]
                         repetitions: [[dict objectForRequiredKey: PLAlertRepetitions] unsignedShortValue]];
    return self;
}

@end
