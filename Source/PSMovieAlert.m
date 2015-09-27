//
//  PSMovieAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <QTKit/QTKit.h>
#import <QuickTime/Movies.h>
#import "PSAudioAlert.h" // XXX transitional
#import "PSMovieAlert.h"
#import "PSMovieAlertController.h"
#import "NSDictionary-NJRExtensions.h"
#import "QTMovie-NJRExtensions.h"
#import "BDAlias.h"

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSString
static NSString * const PLAlertAlias = @"alias"; // NSData

@implementation PSMovieAlert

+ (PSMovieAlert *)alertWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;
{
    return [[[self alloc] initWithMovieFileAlias: anAlias repetitions: numReps] autorelease];
}

- (id)initWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned int)numReps;
{
    if ( (self = [super initWithRepetitions: numReps]) != nil) {
        NSString *path = [anAlias fullPath];
        if (path == nil) {
            [self release];
            [NSException raise: PSAlertCreationException format: NSLocalizedString(@"Can't locate media to play as alert.", "Exception message on PSMovieAlert initialization when alias doesn't resolve")];
        }
        alias = [anAlias retain];
	QTMovie *movie = [[QTMovie alloc] initWithFile: path error: NULL];
        if (movie == nil) {
            [self release];
            self = nil;
        } else {
            hasAudio = [movie NJR_hasAudio];
            hasVideo = [movie NJR_hasVideo];
            
            if (!hasAudio && !hasVideo) {
                [self release]; self = nil;
            }
        }
	[movie release];
    }
    
    return self;
}

- (BOOL)hasVideo;
{
    return hasVideo;
}

- (BOOL)requiresPesterFrontmost;
{
    return hasVideo;
}

- (QTMovie *)movie;
{
    NSString *path = [alias fullPath];
    if (path == nil)
	return nil;
    
    return [[[QTMovie alloc] initWithFile: path error: NULL] autorelease];
}

- (BDAlias *)movieFileAlias;
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

    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"PSMovieAlert (%@%@): %@, repeats %hu times%@", hasAudio ? @"A" : @"", hasVideo ? @"V" : @"", [alias fullPath], repetitions, hasAudio && outputVolume != PSMediaAlertNoVolume ? [NSString stringWithFormat: @" at %.0f%% volume", outputVolume * 100] : @""];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    // XXX no, do this earlier
    PSAudioAlert *audioAlert = [[PSAudioAlert alloc] initWithAudioFileAlias: alias repetitions: repetitions];
    if (audioAlert != nil) {
        [audioAlert triggerForAlarm: alarm];
        return;
    }
    [PSMovieAlertController newControllerWithAlarm: alarm movieAlert: self];
}

- (NSAttributedString *)actionDescription;
{
    clock_t before = clock();
    BOOL isStatic = [[self movie] NJR_isStatic];
    NSLog(@"isStatic: %f", (clock() - before) / (float)CLOCKS_PER_SEC);
    NSMutableAttributedString *string = [[(isStatic ? @"Show " : @"Play ") small] mutableCopy];
    NSString *kindString = nil, *name = [alias displayNameWithKindString: &kindString];
    if (name == nil) name = NSLocalizedString(@"<<can't locate media file>>", "Movie alert description surrogate for media display name when alias doesn't resolve");
    else [string appendAttributedString: [[NSString stringWithFormat: @"%@ ", kindString] small]];
    [string appendAttributedString: [name underlined]];
    if (repetitions > 1 && !isStatic) {
        [string appendAttributedString: [[NSString stringWithFormat: @" %hu times", repetitions] small]];
    }
    if (hasAudio && outputVolume != PSMediaAlertNoVolume) {
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
        [self initWithMovieFileAlias: [BDAlias aliasWithData: [dict objectForRequiredKey: PLAlertAlias]]
                         repetitions: [[dict objectForRequiredKey: PLAlertRepetitions] unsignedShortValue]];
    return self;
}

@end
