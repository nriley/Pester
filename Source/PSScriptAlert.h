//
//  PSScriptAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlert.h"

@class BDAlias;

@interface PSScriptAlert : PSAlert {
    BDAlias *alias;
}

+ (PSScriptAlert *)alertWithScriptFileAlias:(BDAlias *)anAlias;
- (id)initWithScriptFileAlias:(BDAlias *)anAlias;

@end
