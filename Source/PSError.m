//
//  PSError.m
//  Pester
//
//  Created by Nicholas Riley on Sun Dec 29 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSError.h"

static NSString * const PSErrorException = @"PSErrorException";

@implementation PSError

+ (PSError *)error;
{
    return [[self alloc] init];
}

- (void)dealloc;
{
    [reasons release]; reasons = nil;
    [operation release]; operation = nil;
    [super dealloc];
}

- (NSCountedSet *)reasons;
{
    if (reasons == nil)
        reasons = [[NSCountedSet alloc] initWithCapacity: 2];
    return reasons;
}

- (void)addException:(NSException *)exception;
{

}

- (void)raiseIfNeededForOperation:(NSString *)anOperation count:(unsigned)aCount;
{
    if (reasons != nil && [reasons count] > 0) {
        // NSMutableString *
        [self autorelease];
        [NSException raise: PSErrorException
                    format: @"Pester encountered errors while %@ %@."];
    } else {
        [self release];
    }
}

@end

/* Use cases:
   - PSAlerts => can't restore one or more alerts, keep the rest
   - 

   Need to add error to initWithPropertyList: protocol, otherwise we can't get back partially-formed objects.
   - (id)initWithPropertyList:(NSDictionary *)dict error:(PSException **)exception;

 */