//
//  PSError.h
//  Pester
//
//  Created by Nicholas Riley on Sun Dec 29 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSError : NSObject {
    NSCountedSet *reasons;
    NSString *operation;
    unsigned count;
}

// create an error object
+ (PSError *)error;

// raise exception, invalidates error object
- (void)raiseIfNeededForOperation:(NSString *)anOperation count:(unsigned)aCount;

@end
