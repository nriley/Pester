//
//  NJRDateFormatter.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRDateFormatter.h"


@implementation NJRDateFormatter

// workaround for bug in Jaguar (and earlier?) NSCalendarDate dateWithNaturalLanguageString:
NSString * stringByRemovingSurroundingWhitespace(NSString *string) {
    static NSCharacterSet *nonWhitespace = nil;
    NSRange firstValidCharacter, lastValidCharacter;

    if (!nonWhitespace) {
        nonWhitespace = [[[NSCharacterSet characterSetWithCharactersInString:
            @" \t\r\n"] invertedSet] retain];
    }

    firstValidCharacter = [string rangeOfCharacterFromSet:nonWhitespace];
    if (firstValidCharacter.length == 0)
        return @"";
    lastValidCharacter = [string rangeOfCharacterFromSet:nonWhitespace options:NSBackwardsSearch];

    if (firstValidCharacter.location == 0 && lastValidCharacter.location == [string length] - 1)
        return string;
    else
        return [string substringWithRange:NSUnionRange(firstValidCharacter, lastValidCharacter)];
}


- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    NSCalendarDate *date;
    if (![self allowsNaturalLanguage])
        return [super getObjectValue: anObject forString: string errorDescription: error];
    if (string == nil) return nil;
    NS_DURING // dateWithNaturalLanguageString: can throw an exception
        date = [NSCalendarDate dateWithNaturalLanguageString: stringByRemovingSurroundingWhitespace(string)];
    NS_HANDLER
        if (error != nil) *error = [localException reason];
        NS_VALUERETURN(NO, BOOL);
    NS_ENDHANDLER
    if (date == nil) return [super getObjectValue: anObject forString: string errorDescription: error];
    *anObject = date;
    return YES;
}

@end
