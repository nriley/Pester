//
//  PSDockBounceAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSDockBounceAlert.h"

static PSDockBounceAlert *PSDockBounceAlertShared;

@implementation PSDockBounceAlert

+ (PSAlert *)alert;
{
    if (PSDockBounceAlertShared == nil)
        PSDockBounceAlertShared = [[PSDockBounceAlert alloc] init];
    return PSDockBounceAlertShared;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [NSApp requestUserAttention: NSInformationalRequest];
    [NSApp activateIgnoringOtherApps: YES];
    [NSApp cancelUserAttentionRequest: NSInformationalRequest];
}

@end
