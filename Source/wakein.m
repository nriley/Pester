//
//  wakein.m
//  Pester
//
//  Created by Nicholas Riley on Tue Mar 11 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "wakein.h"
#import "unistd.h"
#import "PSPowerManager.h"

void usage() {
    fprintf(stderr, "usage: wakein secs\n");
    exit(PSWakeErrorSyntax);
}

int main(int argc, const char *argv[])
{
    [[NSAutoreleasePool alloc] init];

    if (argc != 2) usage();

    long long secs;
    if (![[NSScanner scannerWithString: [NSString stringWithUTF8String: argv[1]]] scanLongLong: &secs])
        usage();

    if (secs < 0 || secs > ULONG_MAX)
        usage();

    if (geteuid() != 0) {
        fprintf(stderr, "wakein: must be root\n");
        return PSWakeErrorPermissions;
    }

    NS_DURING
        [PSPowerManager setWakeInterval: secs];
    NS_HANDLER
        fprintf(stderr, "%s\n", [[localException description] UTF8String]);
        return PSWakeErrorException;
    NS_ENDHANDLER

    return 0;
}
