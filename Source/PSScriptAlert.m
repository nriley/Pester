//
//  PSScriptAlert.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSScriptAlert.h"
#import "BDAlias.h"
#import "NDAppleScriptObject.h"

@implementation PSScriptAlert

+ (PSScriptAlert *)alertWithScriptFileAlias:(BDAlias *)anAlias;
{
    return [[[self alloc] initWithScriptFileAlias: anAlias] autorelease];
}

- (id)initWithScriptFileAlias:(BDAlias *)anAlias;
{
    if ( (self = [super init]) != nil) {
        alias = [anAlias retain];
    }
    return self;
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    NDAppleScriptObject *as = [NDAppleScriptObject appleScriptObjectWithContentsOfFile: [alias fullPath]];

    if (as != nil) {
        [as execute];
    }
}
@end
