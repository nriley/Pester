//
//  PSMovieAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSAlert.h"

@class BDAlias;

@interface PSMovieAlert : PSAlert {
    BDAlias *alias;
    NSMovie *movie;
    unsigned short repetitions;
    BOOL hasAudio;
    BOOL hasVideo;
}

+ (PSMovieAlert *)alertWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;

- (id)initWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned int) numReps;

- (BOOL)hasVideo;
- (NSMovie *)movie;
- (BDAlias *)movieFileAlias;
- (unsigned short)repetitions;

@end
