//
//  NJRIntegerFilter.m
//  HostLauncher
//
//  Created by Nicholas Riley on Tue Dec 18 2001.
//  Copyright (c) 2001 Nicholas Riley. All rights reserved.
//

// based on MyIntegerFilter, later VRIntegerNumberFilter
// Copyright © 2001-2002 Bill Cheeseman. All rights reserved.

#import "NJRIntegerFilter.h"

@implementation NJRIntegerFilter

// Input validation

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error;
{
    // Override method to enable NSControl delegate method control:didFailToValidatePartialString:errorDescription: to reject invalid keypresses. Filters out keyboard input characters other than 0..9.
    if ([[*partialStringPtr substringWithRange:NSMakeRange(origSelRange.location, (*proposedSelRangePtr).location - origSelRange.location)] rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet] options:NSLiteralSearch].location != NSNotFound) {
        *error = NSLocalizedString(@"Input is not an integer.", @"Presented when user value not a numeric digit");
        return NO; // Reject *partialStringPtr as typed, invoke delegate method for error handling
    }
    *error = nil;
    return YES; // Accept *partialStringPtr as typed
}

@end
