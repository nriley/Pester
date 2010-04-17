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
static NMRec nmr;

@interface PSDockBounceAlert (Private)
- (void)_stopBouncing;
@end

@implementation PSDockBounceAlert

+ (PSAlert *)alert;
{
    if (PSDockBounceAlertShared == nil) {
        PSDockBounceAlertShared = [[PSDockBounceAlert alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver: PSDockBounceAlertShared selector: @selector(_stopBouncing) name: PSAlarmAlertStopNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: PSDockBounceAlertShared selector: @selector(_stopBouncing) name:NSApplicationDidBecomeActiveNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: PSDockBounceAlertShared selector: @selector(_stopBouncing) name:PSApplicationWillReopenNotification object: nil];
	
	bzero(&nmr, sizeof(nmr));
	nmr.nmMark = 1;
	nmr.qType = nmType;
    }
    
    return PSDockBounceAlertShared;
}

- (void)_stopBouncing;
{
    if ((void *)nmr.nmRefCon != self)
	return;
    
    nmr.nmRefCon = 0;
    NMRemove(&nmr);
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    if (nmr.nmRefCon == 0) {
	nmr.nmRefCon = (long)self;
	NMInstall(&nmr);
    }

    [self completedForAlarm: alarm];
}

- (NSAttributedString *)actionDescription;
{
    return [@"Bounce Dock icon" small];
}

#pragma mark property list serialization (Pester 1.1)

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    [self release];
    return [[PSDockBounceAlert alert] retain];
}
        
@end
