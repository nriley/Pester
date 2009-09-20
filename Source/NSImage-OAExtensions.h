// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/OpenStepExtensions.subproj/NSImage-OAExtensions.h,v 1.14 2002/03/09 01:53:54 kc Exp $

#import <AppKit/NSImage.h>

@class NSMutableSet;

@interface NSImage (OAExtensions)

+ (NSImage *)imageNamed:(NSString *)imageName inBundle:(NSBundle *)aBundle;

@end
