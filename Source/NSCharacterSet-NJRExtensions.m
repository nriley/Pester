//
//  NSCharacterSet-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sun Nov 17 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSCharacterSet-NJRExtensions.h"


@implementation NSCharacterSet (NJRExtensions)

static NSCharacterSet *_typeSelectSet = nil;

+ (NSCharacterSet *)typeSelectSet {
    if (_typeSelectSet == nil) {
        NSMutableCharacterSet *set;
        set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [set formUnionWithCharacterSet: [NSCharacterSet punctuationCharacterSet]];
        [set formUnionWithCharacterSet: [NSCharacterSet whitespaceCharacterSet]];
        _typeSelectSet = [set copy]; // make immutable again - for efficiency
        [set release];
    }
    return _typeSelectSet;
}

@end
