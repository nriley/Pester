//
//  PSAlerts.h
//  Pester
//
//  Created by Nicholas Riley on Sat Dec 21 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "PSPropertyListSerialization.h"

@class PSAlert, PSAlarm;

@interface PSAlerts : NSObject <PSPropertyListSerialization>
{
    NSMutableArray *alerts;
    BOOL requirePesterFrontmost;
}

- (id)init;
- (id)initWithPesterVersion1Alerts;

- (void)addAlert:(PSAlert *)alert;
- (void)removeAlerts;

- (NSArray *)allAlerts;
- (NSEnumerator *)alertEnumerator;
- (BOOL)requirePesterFrontmost; // do any alerts require Pester be in front?

- (void)triggerForAlarm:(PSAlarm *)alarm;

- (NSAttributedString *)prettyList;

@end
