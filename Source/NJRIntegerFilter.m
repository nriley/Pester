//
//  NJRIntegerFilter.m
//  HostLauncher
//
//  Created by Nicholas Riley on Tue Dec 18 2001.
//  Copyright (c) 2001 Nicholas Riley. All rights reserved.
//

// based on MyIntegerFilter
// Copyright © 2001 Bill Cheeseman. All rights reserved.

#import "NJRIntegerFilter.h"

@implementation NJRIntegerFilter

// Input filter

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error {

    // Override method to enable NSControl delegate method control:didFailToValidatePartialString:errorDescription: to
    // reject invalid keypresses. Filters out keyboard input characters other than "1" .. "9".
    if ([[*partialStringPtr substringWithRange:NSMakeRange(origSelRange.location, (*proposedSelRangePtr).location - origSelRange.location)] rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet] options:NSLiteralSearch].location != NSNotFound) {
        *error = NSLocalizedString(@"Input is not an integer", @"Presented when user value not a numeric digit");
        return NO; // Reject *partialStringPtr as typed, invoke delegate method
    }

    if ([*partialStringPtr length] == 0) {
        // Work around NSFormatter issue in Mac OS X 10.0.
        [[[NSApp keyWindow] fieldEditor:NO forObject:nil] setSelectedRange:*proposedSelRangePtr];
    }

    return YES; // Accept *partialStringPtr as typed
}

@end
