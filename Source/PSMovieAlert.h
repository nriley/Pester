//
//  PSMovieAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <QTKit/QTKit.h>
#import "PSMediaAlert.h"

@class BDAlias;

@interface PSMovieAlert : PSMediaAlert {
    BDAlias *alias;
    QTMovie *movie;
    BOOL hasAudio;
    BOOL hasVideo;
}

+ (PSMovieAlert *)alertWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;

- (id)initWithMovieFileAlias:(BDAlias *)anAlias repetitions:(unsigned int) numReps;

- (BOOL)hasVideo;
- (QTMovie *)movie;
- (BDAlias *)movieFileAlias;

@end
