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

+ (NSImage *)imageNamed:(NSString *)imageName inBundleForClass:(Class)aClass;
+ (NSImage *)imageNamed:(NSString *)imageName inBundle:(NSBundle *)aBundle;
+ (NSImage *)imageForFileType:(NSString *)fileType;
    // Caching wrapper for -[NSWorkspace iconForFileType:].  This method is not thread-safe at the moment.
+ (NSImage *)draggingIconWithTitle:(NSString *)title andImage:(NSImage *)image;

- (void)drawFlippedInRect:(NSRect)rect operation:(NSCompositingOperation)op fraction:(float)delta;
- (void)drawFlippedInRect:(NSRect)rect operation:(NSCompositingOperation)op;

    // Puts the image on the pasteboard as TIFF, and also supplies data from any PDF, EPS, or PICT representations available. Returns the number of types added to the pasteboard and adds their names to notThese. This routine uses -addTypes:owner:, so the pasteboard must have previously been set up using -declareTypes:owner.
- (int)addDataToPasteboard:(NSPasteboard *)aPasteboard exceptTypes:(NSMutableSet *)notThese;

@end
