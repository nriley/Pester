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

+ (void)stopBouncing;
{
    [NSApp cancelUserAttentionRequest: NSInformationalRequest];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [NSApp requestUserAttention: NSInformationalRequest];
    [[self class] performSelector: @selector(stopBouncing) withObject: nil afterDelay: 1 inModes: [NSArray arrayWithObject: NSDefaultRunLoopMode]];
    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Bounce dock icon" small];
}

#pragma mark property list serialization (Pester 1.1)

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    [self release];
    return [[PSDockBounceAlert alert] retain];
}
        
@end
