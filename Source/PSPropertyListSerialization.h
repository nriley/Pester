//
//  PSPropertyListSerialization.h
//  Pester
//
//  Created by Nicholas Riley on Sat Dec 21 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JRErr.h"


@protocol PSPropertyListSerialization

// 1.1 only, deprecated when we move to keyed archiving
- (NSDictionary *)propertyListRepresentation;

// no [super initWithPropertyList:error:] in PSAlert subclasses - infinite recursion will result!
- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;

// Note that some *partially* initialized objects can return both an object and an NSError.
// PSAlerts and PSAlarm are currently the only examples; both contain a JRErrExpressionAdapter which checks the error rather than the return value.  Assign inside the JRThrowErr and declare the variable as __block if necessary.

@end
