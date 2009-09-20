// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "NSImage-OAExtensions.h"

#import <AppKit/AppKit.h>

// RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSImage-OAExtensions.m,v 1.17 2002/03/09 01:53:54 kc Exp $")

@implementation NSImage (OAExtensions)

+ (NSImage *)imageNamed:(NSString *)imageName inBundle:(NSBundle *)aBundle;
{
    NSImage *image;
    NSString *path;

    image = [self imageNamed:imageName];
    if (image && [image size].width != 0)
        return image;

    path = [aBundle pathForImageResource:imageName];
    if (!path)
        return nil;

    image = [[NSImage alloc] initWithContentsOfFile:path];
    [image setName:imageName];

    return [image autorelease];
}

@end
