//
//  PSSoundAlert.m
//  Pester
//
//  Created by Nicholas Riley on 9/28/15.
//
//

#import "PSSoundAlert.h"
#import "PSAlarmAlertController.h"
#import "NSDictionary-NJRExtensions.h"
#import "NJRSoundDevice.h"
#import "BDAlias.h"

// property list keys
static NSString * const PLAlertAlias = @"alias"; // NSData

@implementation PSSoundAlert

+ (PSSoundAlert *)alertWithSoundFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;
{
    return [[[self alloc] initWithSoundFileAlias: anAlias repetitions: numReps] autorelease];
}

// shared partial initializer - requires superclass initializer be run first
- (id)_initWithSoundFileAlias:(BDAlias *)anAlias;
{
    NSString *path = [anAlias fullPath];
    if (path == nil) {
        [self release];
        [NSException raise: PSAlertCreationException format: NSLocalizedString(@"Can't locate sound to play as alert.", "Exception message on PSSoundAlert initialization when alias doesn't resolve")];
    }
    alias = [anAlias retain];
    sound = [[NSSound alloc] initWithContentsOfFile: path byReference: YES];
    if (sound == nil) {
        [self release];
        self = nil;
    }
    [sound release];
    sound = nil;

    return self;
}

- (id)initWithSoundFileAlias:(BDAlias *)anAlias repetitions:(unsigned int)numReps;
{
    if ( (self = [super initWithRepetitions: numReps]) != nil)
        self = [self _initWithSoundFileAlias: anAlias];

    return self;
}

- (BDAlias *)soundFileAlias;
{
    return alias;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [alias release];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"PSSoundAlert: %@, repeats %hu times%@", [alias fullPath], repetitions, outputVolume != PSMediaAlertNoVolume ? [NSString stringWithFormat: @" at %.0f%% volume", outputVolume * 100] : @""];
}

- (void)sound:(NSSound *)aSound didFinishPlaying:(BOOL)didFinish;
{
    // NSLog(@"%@ - %hu left, didFinish:%d", self, repetitionsRemaining, didFinish);
    if (repetitionsRemaining <= 1 || !didFinish) {
        [self completedForAlarm: alarm];
        [sound release];
        sound = nil;
        [self release];
        return;
    }
    [sound play];
    repetitionsRemaining--;
}

- (void)_stopPlaying:(NSNotification *)notification;
{
    repetitionsRemaining = 0;
    [sound stop];
}

- (void)triggerForAlarm:(PSAlarm *)anAlarm;
{
    alarm = anAlarm;
    repetitionsRemaining = repetitions;

    sound = [[NSSound alloc] initWithContentsOfFile: [alias fullPath] byReference: YES];
    if (sound == nil) {
        NSLog(@"Can't init NSSound with %@", self);
        [self completedForAlarm: alarm];
        return;
    }

    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_stopPlaying:) name: PSAlarmAlertStopNotification object: nil];

    [self retain];
    sound.volume = outputVolume;
    sound.playbackDeviceIdentifier = [NJRSoundDevice defaultOutputDevice].uid;
    sound.delegate = self;

    [sound play];
}

- (NSAttributedString *)actionDescription;
{
    NSMutableAttributedString *string = [[@"Play " small] mutableCopy];
    NSString *kindString = nil, *name = [alias displayNameWithKindString: &kindString];
    if (name == nil) name = NSLocalizedString(@"<<can't locate sound file>>", "Sound alert description surrogate for sound display name when alias doesn't resolve");
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
    [plAlert setObject: [alias aliasData] forKey: PLAlertAlias];
    return [plAlert autorelease];
}

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    if ( (self = [super initWithPropertyList: dict error: error]) != nil)
        self = [self _initWithSoundFileAlias: [BDAlias aliasWithData: [dict objectForRequiredKey: PLAlertAlias]]];
    return self;
}

@end
