//
//  PSMovieAlertController.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmAlertController.h"
#import "PSMovieAlertController.h"
#import "PSMovieAlert.h"
#import "NSMovie-NJRExtensions.h"
#import <QuickTime/Movies.h>

// XXX if you specify a truly tiny movie, obey the minimum window size to compensate

@implementation PSMovieAlertController

+ (PSMovieAlertController *)controllerWithAlarm:(PSAlarm *)alarm movieAlert:(PSMovieAlert *)alert;
{
    return [[self alloc] initWithAlarm: alarm movieAlert: alert];
}

- (void)play;
{
    NSTimeInterval delay;
    if (repetitions == 0) return;
    if (IsMovieDone((Movie)theMovie) || repetitionsRemaining == repetitions) {
        if (repetitionsRemaining == 0) {
            [self close];
            return;
        }
        repetitionsRemaining--;
        [movieView gotoBeginning: self];
        [movieView start: self];
    }
    delay = (GetMovieDuration((Movie)theMovie) - GetMovieTime((Movie)theMovie, NULL)) / (double)GetMovieTimeScale((Movie)theMovie);
    [self performSelector: @selector(play) withObject: nil afterDelay: delay inModes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
}

- (id)initWithAlarm:(PSAlarm *)alarm movieAlert:(PSMovieAlert *)alert;
{
    if ([self initWithWindowNibName: @"Movie alert"]) {
        NSMovie *movie = [alert movie];
        NSWindow *window = [self window]; // connect outlets
        [movieView setMovie: movie];
        theMovie = [movie QTMovie];
        if ([alert hasVideo]) {
            NSRect screenRect = [[window screen] visibleFrame];
            float magnification = 1.0;
            NSSize movieSize;
            NSRect frame;
            screenRect.size.height -= [window frame].size.height - [[window contentView] frame].size.height; // account for height of window frame
            while (1) {
                movieSize = [movieView sizeForMagnification: magnification];
                movieSize.height -= 16; // controller is hidden, but its size is included (documented, ergh)
                if (movieSize.width > screenRect.size.width || movieSize.height > screenRect.size.height)
                    magnification /= 2;
                else
                    break;
            }
            [window setContentSize: movieSize];
            [window center];
            frame = [window frame];
            frame.origin.y -= 250; // appear below notifier window
            if (frame.origin.y < screenRect.origin.y) frame.origin.y = screenRect.origin.y;
            [window setFrame: frame display: NO];
            [window setTitle: [alarm message]];
            [[self window] orderFrontRegardless];
        }
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(close) name: PSAlarmAlertStopNotification object: nil];
        repetitions = [alert repetitions];
        repetitionsRemaining = repetitions;
        if (![movie isStatic]) [self play]; // if it's an image, don't close the window automatically
    }
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

@end

@implementation PSMovieAlertController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    repetitions = 0;
    [movieView stop: self];
    [self release];
    // note: there may still be a retained copy of this object until the runloop timer has let go of us at the end of the current movie playback cycle; donÕt worry about it.
}

@end