//
//  NSMovie-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NSMovie (NJRExtensions)

- (BOOL)hasAudio;
- (BOOL)hasVideo;
- (BOOL)isStatic;

@end
