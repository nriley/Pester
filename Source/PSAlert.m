//
//  PSAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlert.h"


@implementation PSAlert

+ (PSAlert *)alert;
{
    NSAssert(NO, @"Class is abstract");
    return nil;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NSAssert(NO, @"Class is abstract");
}

@end
