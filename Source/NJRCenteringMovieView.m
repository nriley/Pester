//
//  NJRCenteringMovieView.m
//  Pester
//
//  Created by Nicholas Riley on Fri Jan 03 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRCenteringMovieView.h"
#import <QuickTime/Movies.h>

@implementation NJRCenteringMovieView

// from _MacTech_ December 2002, p. 76

- (NSRect)movieRect;
{
    NSRect viewRect = [super movieRect];
    Movie qtMovie = [[self movie] QTMovie];
    Rect movieRect = {0, 0, 0, 0};

    GetMovieNaturalBoundsRect(qtMovie, &movieRect);

    float movieWidth = movieRect.right - movieRect.left;
    float movieHeight = movieRect.bottom - movieRect.top;

    if ( (movieWidth <= viewRect.size.width) &&
         (movieHeight <= viewRect.size.height) ) {
        // Movie is smaller than or equal to the view size; just center the movie
        viewRect.origin.y += (int)((viewRect.size.height - movieHeight) / 2.);
        viewRect.size.height = movieHeight;

        viewRect.origin.x += (int)((viewRect.size.width - movieWidth) / 2.);
        viewRect.size.width = movieWidth;
    } else {
        // We need to scale down movie, centering horizontally and vertically
        float movieRatio = movieWidth / (float)movieHeight;
        float viewRatio = viewRect.size.width / viewRect.size.height;

        if (movieRatio > viewRatio) {
            // Movie is wider than will fit; rescale.
            float newHeight = viewRect.size.width / movieRatio;

            viewRect.origin.y += (int)((viewRect.size.height - newHeight) / 2.);
            viewRect.size.height = newHeight;
        } else {
            // Movie is taller than will fit (or has the ideal aspect ratio); rescale.
            float newWidth = viewRect.size.height * movieRatio;

            viewRect.origin.x += (int) ((viewRect.size.width - newWidth) / 2.);
            viewRect.size.width = newWidth;
        }
    }
    return viewRect;
}

@end
