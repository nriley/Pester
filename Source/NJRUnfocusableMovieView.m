//
//  NJRUnfocusableMovieView.m
//  Pester
//
//  Created by Nicholas Riley on Sun Dec 15 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRUnfocusableMovieView.h"


@implementation NJRUnfocusableMovieView

- (BOOL)acceptsFirstResponder;
{
    return NO;
}

@end
