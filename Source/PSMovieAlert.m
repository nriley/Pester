//
//  PSMovieAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <QuickTime/Movies.h>
#import "PSMovieAlert.h"
#import "PSMovieAlertController.h"
#import "NSDictionary-NJRExtensions.h"
#import "NSMovie-NJRExtensions.h"
#import "BDAlias.h"

// property list keys
static NSString * const PLAlertRepetitions = @"times"; // NSString
static NSString * const PLAlertAlias = @"alias"; // NSData

@implementation PSMovieAlert

+ (PSMovieAlert *)alertWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;
{
    return [[[self alloc] initWithMovieFileAlias: anAlias repetitions: numReps] autorelease];
}

- (id)initWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned int) numReps;
{
    if ( (self = [super init]) != nil) {
        NSString *path = [anAlias fullPath];
        if (path == nil) {
            [self release];
            [NSException raise: PSAlertCreationException format: NSLocalizedString(@"Can't locate media to play as alert.", "Exception message on PSMovieAlert initialization when alias doesn't resolve")];
        }
        alias = [anAlias retain];
        repetitions = numReps;
        // XXX if we support remote movie URLs, need to call EnterMovies() ourselves at least in Jaguar (_MacTech_ December 2002, p. 64); also should do async movie loading (p. 73Ð74).
        movie = [[NSMovie alloc] initWithURL: [NSURL fileURLWithPath: path] byReference: YES];
        if (movie == nil) {
            [self release];
            self = nil;
        } else {
            hasAudio = [movie hasAudio];
            hasVideo = [movie hasVideo];
            
            if (!hasAudio && !hasVideo) {
                [self release]; self = nil;
            }
        }
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

- (NSMovie *)movie;
{
    return movie;
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
    [movie release];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"PSMovieAlert (%@%@): %@, repeats %hu times", hasAudio ? @"A" : @"", hasVideo ? @"V" : @"", [alias fullPath], repetitions];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [PSMovieAlertController controllerWithAlarm: alarm movieAlert: self];
}

- (NSAttributedString *)actionDescription;
{
    BOOL isStatic = [movie isStatic];
    NSMutableAttributedString *string = [[(isStatic ? @"Show " : @"Play ") small] mutableCopy];
    NSString *kindString = nil, *name = [alias displayNameWithKindString: &kindString];
    if (name == nil) name = NSLocalizedString(@"<<can't locate media file>>", "Movie alert description surrogate for media display name when alias doesn't resolve");
    else [string appendAttributedString: [[NSString stringWithFormat: @"%@ ", kindString] small]];
    [string appendAttributedString: [name underlined]];
    if (repetitions > 1 && !isStatic) {
        [string appendAttributedString: [[NSString stringWithFormat: @" %hu times", repetitions] small]];
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

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    return [self initWithMovieFileAlias: [BDAlias aliasWithData: [dict objectForRequiredKey: PLAlertAlias]]
                            repetitions: [[dict objectForRequiredKey: PLAlertRepetitions] unsignedShortValue]];
}

@end
