//
//  PSPropertyListSerialization.h
//  Pester
//
//  Created by Nicholas Riley on Sat Dec 21 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PSPropertyListSerialization

// 1.1 only, deprecated when we move to keyed archiving
- (NSDictionary *)propertyListRepresentation;
// subclasses should NOT call [super initWithPropertyList:] - infinite recursion will result!
- (id)initWithPropertyList:(NSDictionary *)dict;

@end
