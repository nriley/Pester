//
//  PSMovieAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "AVAsset-NJRExtensions.h"
#import "PSMovieAlert.h"
#import "PSMovieAlertController.h"
#import "NSDictionary-NJRExtensions.h"
#import "BDAlias.h"

// property list keys
static NSString * const PLAlertAlias = @"alias"; // NSData

@implementation PSMovieAlert

+ (PSMovieAlert *)alertWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;
{
    return [[[self alloc] initWithMovieFileAlias: anAlias repetitions: numReps] autorelease];
}

// shared partial initializer - requires superclass initializer be run first
- (id)_initWithMovieFileAlias:(BDAlias *)anAlias;
{
    NSURL *url = [anAlias fileURL];
    if (url == nil) {
        [self release];
        [NSException raise: PSAlertCreationException format: NSLocalizedString(@"Can't locate media to play as alert.", "Exception message on PSMovieAlert initialization when alias doesn't resolve")];
    }
    alias = [anAlias retain];
    AVAsset *asset = [AVAsset assetWithURL: url];
    if (asset == nil || ![asset NJR_hasVideo]) {
        [self release];
        self = nil;
    }

    return self;
}

- (id)initWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned int)numReps;
{
    if ( (self = [super initWithRepetitions: numReps]) != nil)
        self = [self _initWithMovieFileAlias: anAlias];
    
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

- (AVAsset *)asset;
{
    NSURL *url = [alias fileURL];
    if (url == nil)
	return nil;
    
    return [AVAsset assetWithURL: url];
}

- (BDAlias *)movieFileAlias;
{
    return alias;
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
    [PSMovieAlertController newControllerWithAlarm: alarm movieAlert: self];
}

- (NSAttributedString *)actionDescription;
{
    BOOL isStatic = [[self asset] NJR_isStatic];
    NSMutableAttributedString *string = [[(isStatic ? @"Show " : @"Play ") small] mutableCopy];
    NSString *kindString = nil, *name = [alias displayNameWithKindString: &kindString];
    if (name == nil) name = NSLocalizedString(@"<<can't locate media file>>", "Movie alert description surrogate for media display name when alias doesn't resolve");
    else [string appendAttributedString: [[NSString stringWithFormat: @"%@ ", kindString] small]];
    [string appendAttributedString: [name underlined]];
    if (repetitions > 1 && !isStatic) {
        [string appendAttributedString: [[NSString stringWithFormat: @" %hu times", repetitions] small]];
    }
    if (hasAudio && outputVolume != 0) {
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
        self = [self _initWithMovieFileAlias: [BDAlias aliasWithData: [dict objectForRequiredKey: PLAlertAlias]]];
    return self;
}

@end
