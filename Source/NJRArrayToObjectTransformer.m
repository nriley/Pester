//
//  NJRArrayToObjectTransformer.m
//  Pester
//
//  Created by Nicholas Riley on 3/9/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "NJRArrayToObjectTransformer.h"

// Thanks to Florijan Stamenkovic for this implementation.

@implementation NJRArrayToObjectTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return [NSObject class];
}

- (id)transformedValue:(id)value
{
    NSArray *array = value;
    
    if (array == nil || [array count] == 0)
	return nil;
    
    return [array objectAtIndex: 0];
}

- (id)reverseTransformedValue:(id)value
{
    if (value == nil)
	return [NSArray arrayWithObject: [NSNull null]];
    
    return [NSArray arrayWithObject: value];
}

@end
