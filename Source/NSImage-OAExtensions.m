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

+ (NSImage *)imageNamed:(NSString *)imageName inBundleForClass:(Class)aClass;
{
    return [self imageNamed:imageName inBundle:[NSBundle bundleForClass:aClass]];
}

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

+ (NSImage *)imageForFileType:(NSString *)fileType;
    // It turns out that -[NSWorkspace iconForFileType:] doesn't cache previously returned values, so we cache them here.
{
    static NSMutableDictionary *imageDictionary = nil;
    id image;

    // ASSERT_IN_MAIN_THREAD(@"+imageForFileType: is not thread-safe; must be called from the main thread");
    // We could fix this by adding locks around imageDictionary

    if (!fileType)
        return nil;
        
    if (imageDictionary == nil)
        imageDictionary = [[NSMutableDictionary alloc] init];

    image = [imageDictionary objectForKey:fileType];
    if (image == nil) {
#ifdef DEBUG
        // Make sure that our caching doesn't go insane (and that we don't ask it to cache insane stuff)
        NSLog(@"Caching workspace image for file type '%@'", fileType);
#endif
        image = [[NSWorkspace sharedWorkspace] iconForFileType:fileType];
        if (image == nil)
            image = [NSNull null];
        [imageDictionary setObject:image forKey:fileType];
    }
    return image != [NSNull null] ? image : nil;
}

#define X_SPACE_BETWEEN_ICON_AND_TEXT_BOX 2
#define X_TEXT_BOX_BORDER 2
#define Y_TEXT_BOX_BORDER 2
static NSDictionary *titleFontAttributes;

+ (NSImage *)draggingIconWithTitle:(NSString *)title andImage:(NSImage *)image;
{
    NSImage *drawImage;
    NSSize imageSize, totalSize;
    NSSize titleSize, titleBoxSize;
    NSRect titleBox;
    NSPoint textPoint;

    NSParameterAssert(image != nil);
    imageSize = [image size];

    if (!titleFontAttributes)
        titleFontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:12.0], NSFontAttributeName, [NSColor textColor], NSForegroundColorAttributeName, nil];

    if (!title || [title length] == 0)
        return image;
    
    titleSize = [title sizeWithAttributes:titleFontAttributes];
    titleBoxSize = NSMakeSize(titleSize.width + 2.0 * X_TEXT_BOX_BORDER, titleSize.height + Y_TEXT_BOX_BORDER);

    totalSize = NSMakeSize(imageSize.width + X_SPACE_BETWEEN_ICON_AND_TEXT_BOX + titleBoxSize.width, MAX(imageSize.height, titleBoxSize.height));

    drawImage = [[NSImage alloc] initWithSize:totalSize];
    [drawImage setFlipped:YES];

    [drawImage lockFocus];

    // Draw transparent background
    [[NSColor colorWithDeviceWhite:1.0 alpha:0.0] set];
    NSRectFill(NSMakeRect(0, 0, totalSize.width, totalSize.height));

    // Draw icon
    [image compositeToPoint:NSMakePoint(0.0, rint(totalSize.height / 2.0 + imageSize.height / 2.0)) operation:NSCompositeSourceOver];
    
    // Draw box around title
    titleBox = NSMakeRect(imageSize.width + X_SPACE_BETWEEN_ICON_AND_TEXT_BOX, floor((totalSize.height - titleBoxSize.height)/2.0), titleBoxSize.width, titleBoxSize.height);
    [[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] set];
    NSRectFill(titleBox);

    // Draw title
    textPoint = NSMakePoint(imageSize.width + X_SPACE_BETWEEN_ICON_AND_TEXT_BOX + X_TEXT_BOX_BORDER, Y_TEXT_BOX_BORDER - 1);

    [title drawAtPoint:textPoint withAttributes:titleFontAttributes];

    [drawImage unlockFocus];

    return [drawImage autorelease];
}

//

- (void)drawFlippedInRect:(NSRect)rect operation:(NSCompositingOperation)op fraction:(float)delta;
{
    CGContextRef context;

    context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context); {
        CGContextTranslateCTM(context, 0, NSMaxY(rect));
        CGContextScaleCTM(context, 1, -1);
        
        rect.origin.y = 0; // We've translated ourselves so it's zero
        [self drawInRect:rect fromRect:NSZeroRect operation:op fraction:delta];
    } CGContextRestoreGState(context);

    /*
        NSAffineTransform *flipTransform;
        NSPoint transformedPoint;
        NSSize transformedSize;
        NSRect transformedRect;

        flipTransform = [[NSAffineTransform alloc] init];
        [flipTransform scaleXBy:1.0 yBy:-1.0];

        transformedPoint = [flipTransform transformPoint:rect.origin];
        transformedSize = [flipTransform transformSize:rect.size];
        [flipTransform concat];
        transformedRect = NSMakeRect(transformedPoint.x, transformedPoint.y + transformedSize.height, transformedSize.width, -transformedSize.height);
        [anImage drawInRect:transformedRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        [flipTransform concat];
        [flipTransform release];
        */
}

- (void)drawFlippedInRect:(NSRect)rect operation:(NSCompositingOperation)op;
{
    [self drawFlippedInRect:rect operation:op fraction:1.0];
}

- (int)addDataToPasteboard:(NSPasteboard *)aPasteboard exceptTypes:(NSMutableSet *)notThese
{
    NSArray *myRepresentations;
    int repIndex, repCount;
    int count = 0;

    if (!notThese)
        notThese = [NSMutableSet set];

#define IF_ADD(typename, dataOwner) if( ![notThese containsObject:(typename)] && [aPasteboard addTypes:[NSArray arrayWithObject:(typename)] owner:(dataOwner)] > 0 )

#define ADD_CHEAP_DATA(typename, expr) IF_ADD(typename, nil) { [aPasteboard setData:(expr) forType:(typename)]; [notThese addObject:(typename)]; count ++; }
        
    /* If we have image representations lying around that already have data in some concrete format, add that data to the pasteboard. */
    myRepresentations = [self representations];
    repCount = [myRepresentations count];
    for(repIndex = 0; repIndex < repCount; repIndex ++) {
        NSImageRep *aRep = [myRepresentations objectAtIndex:repIndex];
            
        if ([aRep respondsToSelector:@selector(PDFRepresentation)]) {
            ADD_CHEAP_DATA(NSPDFPboardType, [(NSPDFImageRep *)aRep PDFRepresentation]);
        }

        if ([aRep respondsToSelector:@selector(PICTRepresentation)]) {
            ADD_CHEAP_DATA(NSPICTPboardType, [(NSPICTImageRep *)aRep PICTRepresentation]);
        }

        if ([aRep respondsToSelector:@selector(EPSRepresentation)]) {
            ADD_CHEAP_DATA(NSPostScriptPboardType, [(NSEPSImageRep *)aRep EPSRepresentation]);
        }
    }
    
    /* Always offer to convert to TIFF. Do this lazily, though, since we probably have to extract it from a bitmap image rep. */
    IF_ADD(NSTIFFPboardType, self) {
        count ++;
    }

    return count;
}

- (void)pasteboard:(NSPasteboard *)aPasteboard provideDataForType:(NSString *)wanted
{
    if ([wanted isEqual:NSTIFFPboardType]) {
        [aPasteboard setData:[self TIFFRepresentation] forType:NSTIFFPboardType];
    }
}



@end
