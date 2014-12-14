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
#import "QTMovie-NJRExtensions.h"
#import "NJRSoundDevice.h"

#include <QuickTime/QuickTime.h>

@implementation PSMovieAlertController

+ (PSMovieAlertController *)newControllerWithAlarm:(PSAlarm *)anAlarm movieAlert:(PSMovieAlert *)anAlert;
{
    // retained until the alert completes
    return [[self alloc] initWithAlarm: anAlarm movieAlert: anAlert];
}

- (void)close;
{
    [super close];
}

- (void)_movieRateDidChange:(NSNotification *)notification;
{
    float newRate = [[[notification userInfo] objectForKey: QTMovieRateDidChangeNotificationParameter]
		     floatValue];
    if (newRate != 0)
	return;
    
    if (repetitions == 0 || repetitionsRemaining == 0) {    
	[self close];
	return;
    }
    repetitionsRemaining--;
    [movieView gotoBeginning: self];
    [movieView play: self];
}

- (void)play;
{
    repetitionsRemaining = repetitions - 1;

    [[NSNotificationCenter defaultCenter] addObserver: self
					     selector: @selector(_movieRateDidChange:)
						 name: QTMovieRateDidChangeNotification
					       object: [movieView movie]];
    [movieView play: self];
}

- (id)initWithAlarm:(PSAlarm *)anAlarm movieAlert:(PSMovieAlert *)anAlert;
{
    if ( (self = [self initWithWindowNibName: @"Movie alert"]) != nil) {
        QTMovie *movie = [anAlert movie];
        NSWindow *window = [self window]; // connect outlets
        alarm = anAlarm;
        alert = anAlert;
        [movieView setMovie: movie];
        if ([alert hasVideo]) {
            NSRect screenRect = [[window screen] visibleFrame];
            NSSize movieSize = [[movie attributeForKey: QTMovieNaturalSizeAttribute] sizeValue];
            NSSize minSize = [window minSize];
            float windowFrameHeight = [window frame].size.height - [[window contentView] frame].size.height;
            NSRect frame;
            screenRect.size.height -= windowFrameHeight;
            minSize.height -= windowFrameHeight;
            while (movieSize.width > screenRect.size.width || movieSize.height > screenRect.size.height) {
                movieSize.width /= 2;
		movieSize.height /= 2;
            }
            if (movieSize.width < minSize.width) movieSize.width = minSize.width;
            if (movieSize.height < minSize.height) movieSize.width = minSize.height;
            [window setContentSize: movieSize];
            [window center];
            frame = [window frame];
            frame.origin.y -= 400; // appear below notifier window - XXX this is very inaccurate, fix
            if (frame.origin.y < screenRect.origin.y) frame.origin.y = screenRect.origin.y;
            [window setFrame: frame display: NO];
            [window setTitle: [alarm message]];
            {	// XXX workaround for (IMO) ugly appearance of Cocoa utility windows
                NSView *miniButton = [window standardWindowButton: NSWindowMiniaturizeButton],
                *zoomButton = [window standardWindowButton: NSWindowZoomButton];
                // NOTE: this will not work if the window is resizable: when the frame is reset, the standard buttons reappear
                [miniButton setFrameOrigin: NSMakePoint(-100, -100)];
                [zoomButton setFrameOrigin: NSMakePoint(-100, -100)];
                [[miniButton superview] setNeedsDisplay: YES];
                [[zoomButton superview] setNeedsDisplay: YES];
            }
            [[self window] orderFrontRegardless];
        }
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(close) name: PSAlarmAlertStopNotification object: nil];
        repetitions = [alert repetitions];
        if ([movie NJR_hasAudio] && [NJRSoundDevice volumeIsNotMutedOrInvalid: [alert outputVolume]]) {
            [movie setVolume: [alert outputVolume]];
#if !__LP64__
	    SetMovieAudioContext([movie quickTimeMovie],
				 [[NJRSoundDevice defaultOutputDevice] quickTimeAudioContext]);
#endif
        }
        if (![movie NJR_isStatic]) [self play]; // if it's an image, don't close the window automatically
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
    [[NSNotificationCenter defaultCenter] removeObserver: self
						    name: QTMovieRateDidChangeNotification
						  object: [movieView movie]];
    [movieView pause: self];
    [alert completedForAlarm: alarm];
    [self autorelease];
    // note: there may still be a retained copy of this object until the runloop timer has let go of us at the end of the current movie playback cycle; donÕt worry about it.
}

@end