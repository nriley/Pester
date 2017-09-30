//
//  NJROperatingSystemVersion.m
//  Pester
//
//  Created by Nicholas Riley on 11/9/14.
//
//

#import <Foundation/Foundation.h>

static NSInteger majorVersion;
static NSInteger minorVersion;
static NSInteger patchVersion;

NSInteger NJROSXMinorVersion(void) {
    if (majorVersion == 0) {
        NSProcessInfo *processInfo = [NSProcessInfo processInfo];
        if ([processInfo respondsToSelector: @selector(operatingSystemVersion)]) {
            NSOperatingSystemVersion version = [processInfo operatingSystemVersion];
            majorVersion = version.majorVersion;
            minorVersion = version.minorVersion;
            patchVersion = version.patchVersion;
        } else {
            // XXX remove when 10.10 required
            SInt32 majorVersion32, minorVersion32, patchVersion32;
            if (Gestalt(gestaltSystemVersionMajor, &majorVersion32) != noErr ||
                Gestalt(gestaltSystemVersionMinor, &minorVersion32) != noErr ||
                Gestalt(gestaltSystemVersionBugFix, &patchVersion32) != noErr) {
                majorVersion = minorVersion = patchVersion = -1;
            } else {
                majorVersion = majorVersion32;
                minorVersion = minorVersion32;
                patchVersion = patchVersion32;
            }
        }
    }

    if (majorVersion != 10)
        return -1;

    return minorVersion;
}
