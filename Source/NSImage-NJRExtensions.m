//
//  NSImage-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Mon Oct 28 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSImage-NJRExtensions.h"


@implementation NSImage (NJRExtensions)

- (NSImage *)bestFitImageForSize:(NSSize)imageSize;
{
    NSSize repSize;
    NSArray *imageReps;
    int i, repCount;
    NSImageRep *preferredRep, *rep;
    imageReps = [self representations];
    repCount = [imageReps count];
    preferredRep = [imageReps objectAtIndex: 0];
    for (i = 1 ; i < repCount ; i++) {
        rep = [imageReps objectAtIndex: i];
        repSize = [rep size];
        if (repSize.width == imageSize.width && repSize.height == imageSize.height) {
            preferredRep = rep;
            break;
        }
        if (repSize.width >= imageSize.width || repSize.height >= imageSize.height) {
            // pick the smallest of the larger representations
            if (repSize.width <= [preferredRep size].width ||
                repSize.height <= [preferredRep size].height) preferredRep = rep;
        } else {
            // or the largest of the smaller representations
            if (([preferredRep size].width > imageSize.width ||
                    [preferredRep size].height > imageSize.height) ||
                // (assuming that the previous preferred rep was smaller, too)
                // XXX fix this in HostLauncher too - or is the FSA code better?
                (repSize.width >= [preferredRep size].width ||
                    repSize.height >= [preferredRep size].height)) preferredRep = rep;
        }
    }
    // Begin workaround code for bug in OS X 10.1 (removeRepresentation: has no effect)
    if ([preferredRep size].width > imageSize.width || [preferredRep size].height > imageSize.height) {
        NSImage *scaledImage = [[NSImage alloc] initWithSize: imageSize];
        NSRect rect = { NSZeroPoint, imageSize };
        [scaledImage setFlipped: [self isFlipped]]; // XXX this works, but is correct?
        [scaledImage lockFocus];
        [preferredRep drawInRect: rect];
        [scaledImage unlockFocus];
        return scaledImage;
    } else if (repCount > 1) {
        NSImage *sizedImage = [[NSImage alloc] initWithSize: [preferredRep size]];
        [sizedImage addRepresentation: preferredRep];
        return sizedImage;
    } else {
        return self;
    }
}

@end
