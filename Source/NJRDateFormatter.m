//
//  NJRDateFormatter.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRDateFormatter.h"

NSUserDefaults *locale;

@implementation NJRDateFormatter

+ (void)initialize;
{
    locale = [[NSUserDefaults standardUserDefaults] retain];
}

+ (NSString *)format:(NSString *)format withoutComponent:(unichar)component;
{
    NSScanner *scanner = [NSScanner scannerWithString: format];
    int formatLength = [format length];
    NSRange range;
    [scanner setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @""]];
    // NSLog(@"format:withoutComponent: trying to excise %c from %@", component, format);
    while ([scanner scanUpToString: @"%" intoString: nil] || ![scanner isAtEnd]) {
        range.location = [scanner scanLocation];
        // NSLog(@"location: %d/%d, remaining: %@%@", range.location, formatLength, [format substringFromIndex: range.location], [scanner isAtEnd] ? @", isAtEnd" : @"");
        // XXX works fine without keeping track of length in 10.1.5; in 10.2, [scanner scanUptoString:intoString:] still returns YES even when scanner is at end and thereÕs nothing left to scan, and if you start accessing the string past the end... *boom*
        if (range.location >= formatLength) break;
        [scanner scanUpToCharactersFromSet: [NSCharacterSet letterCharacterSet] intoString: nil];
        if ([format characterAtIndex: [scanner scanLocation]] == component) {
            if ([scanner scanUpToString: @"%" intoString: nil] && ![scanner isAtEnd]) {
                NSMutableString *mutableFormat = [format mutableCopy];
                if (range.location != 0 && [[NSCharacterSet punctuationCharacterSet] characterIsMember: [format characterAtIndex: range.location - 1]]) {
                    range.location--; // "%I:%M:%S%p" -> "%I:%M%p"
                }
                range.length = [scanner scanLocation] - range.location;
                [mutableFormat deleteCharactersInRange: range];
                format = [mutableFormat copy];
                [mutableFormat release];
                return [format autorelease];
            } else {
                range = [format rangeOfCharacterFromSet: [NSCharacterSet letterCharacterSet] options: NSBackwardsSearch range: NSMakeRange(0, range.location)];
                return [format substringToIndex: NSMaxRange(range)];
            }
        }
    }
    return format;
}

+ (NSString *)localizedDateFormatIncludingWeekday:(BOOL)weekday;
{
    NSString *format = [locale stringForKey: NSDateFormatString];
    if (weekday) return format;
    return [self format: format withoutComponent: (unichar)'A'];
}

+ (NSString *)localizedShortDateFormatIncludingWeekday:(BOOL)weekday;
{
    NSString *format = [locale stringForKey: NSShortDateFormatString];
    if (weekday) return format;
    return [self format: format withoutComponent: (unichar)'A'];
}

NSString *stringByInsertingStringAtLocation(NSString *string, NSString *insert, int location) {
    return [NSString stringWithFormat: @"%@%@%@", [string substringToIndex: location], insert,
        [string substringFromIndex: location]];
}

+ (NSString *)localizedTimeFormatIncludingSeconds:(BOOL)seconds;
{
    NSString *format = [locale stringForKey: NSTimeFormatString];
    NSArray *ampm = [locale arrayForKey: NSAMPMDesignation];
    NSString *am = [ampm objectAtIndex: 0], *pm = [ampm objectAtIndex: 1];
    // work around bug with inconsistent AM/PM and time format
    if ([am isEqualToString: @""] && [pm isEqualToString: @""])
        format = [self format: format withoutComponent: 'p'];
    else {
        NSRange ampmComponentRange = [format rangeOfString: @"%p"];
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
        BOOL needSpaceInFormatString = ![whitespace characterIsMember: [am characterAtIndex: 0]];
        if (ampmComponentRange.location == NSNotFound) // "%1I:%M:%S" -> "%1I:%M:%S%p", "%1I:%M:%S %p"
            format = [format stringByAppendingString: (needSpaceInFormatString ? @" %p" : @"%p")];
        else {
            NSRange whitespaceRange = [format rangeOfCharacterFromSet: whitespace options: NSBackwardsSearch range: NSMakeRange(0, ampmComponentRange.location)];
            if (whitespaceRange.location == NSNotFound) {
                if (needSpaceInFormatString) // "%1I:%M:%S%p" -> "%1I:%M:%S %p"
                    format = stringByInsertingStringAtLocation(format, @" ", ampmComponentRange.location);
                // else "%1I:%M:%S%p" -> no change
            } else {
                if (NSMaxRange(whitespaceRange) == ampmComponentRange.location) { 
                    if (!needSpaceInFormatString) // "%1I:%M:%S %p" -> "%1I:%M:%S%p"
                        format = [[format substringToIndex: whitespaceRange.location] stringByAppendingString: [format substringFromIndex: ampmComponentRange.location]];
                    // else "%1I:%M:%S %p" -> no change
                } else {
                    if (needSpaceInFormatString)
                        format = stringByInsertingStringAtLocation(format, @" ", ampmComponentRange.location);
                    // else "%1I %M:%S%p" -> no change
                }
            }
        }
    }
    if (seconds) return format;
    return [self format: format withoutComponent: 'S'];
}

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
    lastValidCharacter = [string rangeOfCharacterFromSet:nonWhitespace options: NSBackwardsSearch];

    if (firstValidCharacter.location == 0 && lastValidCharacter.location == [string length] - 1)
        return string;
    else
        return [string substringWithRange: NSUnionRange(firstValidCharacter, lastValidCharacter)];
}

- (id)initWithDateFormat:(NSString *)format allowNaturalLanguage:(BOOL)flag;
{
    if ( (self = [super initWithDateFormat: format allowNaturalLanguage: flag]) != nil) {
        NSRange ampmRange = [format rangeOfString: @"%p"];
        NSArray *ampm = [locale arrayForKey: NSAMPMDesignation];
        NSString *am = [ampm objectAtIndex: 0], *pm = [ampm objectAtIndex: 1];
        if (flag && ampmRange.location != NSNotFound &&
            [[locale stringForKey: NSTimeFormatString] rangeOfString: @"%p"].location == NSNotFound && ![am isEqualToString: pm]) {
            // workaround for bug in NSCalendarDate dateWithNaturalLanguageString: discarding AM/PM value when AM/PM designations have spaces in them (of which the use thereof is a workaround for NSDateFormatter discarding the AM/PM value)
            NSMutableString *paddedFormat = [format mutableCopy];
            [paddedFormat replaceCharactersInRange: ampmRange withString: @" %p"];
            alteredLocale = [[locale dictionaryRepresentation] mutableCopy];
            [(NSMutableDictionary *)alteredLocale setObject: paddedFormat forKey: NSTimeFormatString];
            [(NSMutableDictionary *)alteredLocale setObject:
                [NSArray arrayWithObjects: stringByRemovingSurroundingWhitespace(am),
                    stringByRemovingSurroundingWhitespace(pm)] forKey: NSAMPMDesignation];
            [paddedFormat release];
        } else {
            alteredLocale = [(NSDictionary *)locale retain];
        }
    }
    return self;
}

- (void)dealloc;
{
    [alteredLocale release];
    [super dealloc];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    NSCalendarDate *date;
    if (![self allowsNaturalLanguage])
        return [super getObjectValue: anObject forString: string errorDescription: error];
    if (string == nil) return nil;
    NS_DURING // dateWithNaturalLanguageString: can throw an exception
        date = [NSCalendarDate dateWithNaturalLanguageString: stringByRemovingSurroundingWhitespace(string) locale: alteredLocale];
        // NSLog(@"%@: natural language date is %@", string, date);
    NS_HANDLER
        if (error != nil) *error = [localException reason];
        NS_VALUERETURN(NO, BOOL);
    NS_ENDHANDLER
    // [super getObjectValue: anObject forString: string errorDescription: error];
    // NSLog(@"%@: formatter date is %@", string, anObject == nil ? @"(null)" : *anObject);
    if (date == nil) return [super getObjectValue: anObject forString: string errorDescription: error];
    *anObject = date;
    return YES;
}

@end
