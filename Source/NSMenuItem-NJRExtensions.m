//
//  NSMenuItem-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on 11/22/07.
//  Copyright 2007 Nicholas Riley. All rights reserved.
//

#import "NSMenuItem-NJRExtensions.h"

@interface NSMenuItem (Private)
- (void)_setIconRef:(IconRef)iconRef;
@end

@implementation NSMenuItem (NJRExtensions)

// from ICeCoffEE's ICCF_CopyIconRefForPath
- (void)setImageFromPath:(NSString *)path;
{
    IconRef icon;
    FSRef fsr;
    SInt16 label;
    OSStatus err = noErr;
    
    err = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &fsr, NULL);
    if (err != noErr) return;
    
    err = GetIconRefFromFileInfo(&fsr, 0, NULL, kFSCatInfoNone, NULL, kIconServicesNormalUsageFlag, &icon, &label);
    if (err != noErr) return;
    
    [self _setIconRef: icon];
    ReleaseIconRef(icon);
}

@end
