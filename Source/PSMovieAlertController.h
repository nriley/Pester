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
    IBOutlet NSMovieView *movieView;
    void *theMovie; /* Movie */
    unsigned short repetitions;
    unsigned short repetitionsRemaining;    
}

+ (PSMovieAlertController *)controllerWithAlarm:(PSAlarm *)alarm movieAlert:(PSMovieAlert *)alert;

- (id)initWithAlarm:(PSAlarm *)alarm movieAlert:(PSMovieAlert *)alert;

@end
