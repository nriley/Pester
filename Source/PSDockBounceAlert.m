//
//  PSDockBounceAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSDockBounceAlert.h"
#import "PSAlarmAlertController.h"
#import "PSApplication.h"

#include <Carbon/Carbon.h>

static PSDockBounceAlert *PSDockBounceAlertShared;

@interface PSDockBounceAlert (Private)
- (void)_stopBouncing;
@end

@implementation PSDockBounceAlert

+ (instancetype)alert;
{
    if (PSDockBounceAlertShared == nil) {
        PSDockBounceAlertShared = [[PSDockBounceAlert alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver: PSDockBounceAlertShared selector: @selector(_stopBouncing) name: PSAlarmAlertStopNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: PSDockBounceAlertShared selector: @selector(_stopBouncing) name:PSApplicationWillReopenNotification object: nil];
    }
    
    return PSDockBounceAlertShared;
}

- (void)_stopBouncing;
{
    [NSApp cancelUserAttentionRequest: userAttentionRequest];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    userAttentionRequest = [NSApp requestUserAttention: NSCriticalRequest];

    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Bounce Dock icon" small];
}

#pragma mark property list serialization (Pester 1.1)

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    [self release];
    return [[PSDockBounceAlert alert] retain];
}
        
@end
