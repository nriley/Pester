//
//  PSMovieAlertController.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PSAlarm;
@class PSMovieAlert;

@interface PSMovieAlertController : NSWindowController {
    PSAlarm *alarm;
    PSMovieAlert *alert;
    IBOutlet NSMovieView *movieView;
    void *theMovie; /* Movie */
    unsigned short repetitions;
    unsigned short repetitionsRemaining;    
}

+ (PSMovieAlertController *)controllerWithAlarm:(PSAlarm *)anAlarm movieAlert:(PSMovieAlert *)anAlert;

- (id)initWithAlarm:(PSAlarm *)anAlarm movieAlert:(PSMovieAlert *)anAlert;

@end
