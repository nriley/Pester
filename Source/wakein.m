//
//  wakein.m
//  Pester
//
//  Created by Nicholas Riley on Tue Mar 11 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSPowerManager.h"
#import "wakein.h"

// System interfaces
#include <stdio.h>
#include <unistd.h>
// MoreIsBetter interfaces
#include "MoreUNIX.h"
#include "MoreSecurity.h"
#include "MoreCFQ.h"

static OSStatus SetAutoWake(AuthorizationRef auth, CFDictionaryRef request, CFDictionaryRef *result) {
    OSStatus 	err;
    assert(auth != NULL);
    assert(request != NULL);
    assert( result != NULL);
    assert(*result == NULL);
    assert(geteuid() == getuid());
    static const char *kRightName = "net.sabi.Pester.wakein.SetAutoWake";
    static const AuthorizationFlags kAuthFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
    AuthorizationItem   right  = { kRightName, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &right };
    err = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, kAuthFlags, NULL);
    // sometimes we don't get here via authexec, so ignore this
    
    err = MoreSecSetPrivilegedEUID();
    if (err != noErr) return err;
    
    [[NSAutoreleasePool alloc] init];

    NSNumber *wakeTime = [(NSDictionary *)request objectForKey: kPesterWakeTime];
    NSLog(@"setting wake time: %@", wakeTime);
    if (wakeTime == nil) return noErr;

    long long secs = [wakeTime unsignedLongLongValue];
    if (secs < 0 || secs > ULONG_MAX) return paramErr;

    NS_DURING
        [PSPowerManager setWakeInterval: (unsigned long)secs];
    NS_HANDLER
        *result = (CFDictionaryRef)[NSDictionary dictionaryWithObject: [localException description] forKey: kPesterWakeException];
        return ioErr;
    NS_ENDHANDLER

    *result = (CFDictionaryRef)[NSDictionary dictionary];

    return noErr;
}

int main(int argc, const char *argv[]) {
    OSStatus err;
    int result;
    AuthorizationRef auth;

    auth = MoreSecHelperToolCopyAuthRef();
    err = MoreSecDestroyInheritedEnvironment(kMoreSecKeepStandardFilesMask, argv);
    if (err == 0) {
        err = MoreUNIXIgnoreSIGPIPE();
    }
    if (err == 0) {
        err = MoreSecHelperToolMain(STDIN_FILENO, STDOUT_FILENO, auth, SetAutoWake, argc, argv);
    }
    result = MoreSecErrorToHelperToolResult(err);

    return result;
}
