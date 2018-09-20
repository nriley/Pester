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
        NSOperatingSystemVersion version = [processInfo operatingSystemVersion];
        majorVersion = version.majorVersion;
        minorVersion = version.minorVersion;
        patchVersion = version.patchVersion;
    }

    if (majorVersion != 10)
        return -1;

    return minorVersion;
}
