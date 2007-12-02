//
//  NJRDateFormatter.m
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRDateFormatter.h"
#import "ParseDate.h"
#include <dlfcn.h>

// workaround for bug in Jaguar (and earlier?) NSCalendarDate dateWithNaturalLanguageString:
NSString *stringByRemovingSurroundingWhitespace(NSString *string) {
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

static const NSDateFormatterStyle formatterStyles[] = {
    NSDateFormatterShortStyle,
    NSDateFormatterMediumStyle,
    NSDateFormatterLongStyle,
    NSDateFormatterFullStyle,
    NSDateFormatterNoStyle
};

@implementation NJRDateFormatter

#pragma mark initialize-release

+ (void)initialize;
{
    long minorVersion, majorVersion;
    Gestalt(gestaltSystemVersionMajor, &majorVersion);
    Gestalt(gestaltSystemVersionMinor, &minorVersion);
    if (majorVersion != 10)
	return;
    
    NSString *libName;
    if (minorVersion == 4) {
	libName = @"libParseDate-10.4";
    } else if (minorVersion == 5) {
	libName = @"libParseDate-10.5";
    } else {
	return;
    }
    
    NSString *libPath = [[NSBundle mainBundle] pathForResource: libName ofType: @"dylib"];
    if (libPath == nil)
	return;
    
    void *lib = dlopen([libPath fileSystemRepresentation], RTLD_LAZY | RTLD_GLOBAL);
    const char *libError;
    if ( (libError = dlerror()) != NULL) {
	NSLog(@"failed to dlopen %@: %s", libPath, libError);
	return;
    }
    
    parse_natural_language_date = dlsym(lib, "parse_natural_language_date");
    if ( (libError = dlerror()) != NULL) {
	NSLog(@"failed to look up parse_natural_language_date in %@: %s", libPath, libError);
	parse_natural_language_date = NULL;
	return;
    }
}

+ (NJRDateFormatter *)dateFormatter;
{
    NJRDateFormatter *formatter = [[self alloc] init];
    NSMutableArray *tryFormatters = [[NSMutableArray alloc] init];
    
    for (const NSDateFormatterStyle *s = formatterStyles ; *s < NSDateFormatterNoStyle ; *s++) {
	NSDateFormatter *tryFormatter = [[NSDateFormatter alloc] init];
	[tryFormatter setLenient: YES];
	[tryFormatter setTimeStyle: NSDateFormatterNoStyle];
	[tryFormatter setDateStyle: *s];
	[tryFormatters addObject: tryFormatter];
	[tryFormatter release];
    }
    // XXX do this in init
    formatter->tryFormatters = tryFormatters;

    return [formatter autorelease];
}

+ (NJRDateFormatter *)timeFormatter;
{
    NJRDateFormatter *formatter = [[self alloc] init];
    NSMutableArray *tryFormatters = [[NSMutableArray alloc] init];
    
    for (const NSDateFormatterStyle *s = formatterStyles ; *s < NSDateFormatterNoStyle ; *s++) {
	NSDateFormatter *tryFormatter = [[NSDateFormatter alloc] init];
	[tryFormatter setLenient: YES];
	[tryFormatter setTimeStyle: *s];
	[tryFormatter setDateStyle: NSDateFormatterNoStyle];
	[tryFormatters addObject: tryFormatter];
	[tryFormatter release];
    }
    formatter->tryFormatters = tryFormatters;
    
    return [formatter autorelease];
}

- (void)dealloc;
{
    [tryFormatters release]; tryFormatters = nil;
    [super dealloc];
}

#pragma mark primitive formatter 

- (NSString *)stringForObjectValue:(id)obj;
{
    return [super stringForObjectValue: obj];
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj withDefaultAttributes:(NSDictionary *)attrs;
{
    return [super attributedStringForObjectValue: obj
			   withDefaultAttributes: attrs];
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    if ([super getObjectValue: anObject forString: string errorDescription: error])
	return YES;
	
    NSDate *date;
    NSEnumerator *e = [tryFormatters objectEnumerator];
    NSDateFormatter *tryFormatter;
    
    // XXX untested; does this work?
    while ( (tryFormatter = [e nextObject]) != nil) {
	date = [tryFormatter dateFromString: string];
	if (date != nil) goto success;
    }
    
    if (parse_natural_language_date == NULL) return nil;

    date = parse_natural_language_date(string);
    if (date != nil) goto success;
    
    return NO;

success:
    *anObject = date;
    if (error != NULL) *error = nil;
    return YES;
}

#pragma mark miscellaneous

+ (BOOL)naturalLanguageParsingAvailable;
{
    return (parse_natural_language_date != NULL);
}
@end
