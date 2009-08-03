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

static NSDateFormatter *protoFormatter() {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLenient: YES];
    return formatter;
}

static NSDateFormatter *dateFormatterWithStyle(NSDateFormatterStyle style) {
    NSDateFormatter *formatter = protoFormatter();
    [formatter setTimeStyle: NSDateFormatterNoStyle];
    [formatter setDateStyle: style];
    return formatter;
}

static NSDateFormatter *timeFormatterWithStyle(NSDateFormatterStyle style) {
    NSDateFormatter *formatter = protoFormatter();
    [formatter setTimeStyle: style];
    [formatter setDateStyle: NSDateFormatterNoStyle];
    return formatter;
}

static NSDateFormatter *timeFormatterWithFormat(NSString *format) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: format];
    [formatter setLenient: NO];
    return formatter;
}

static const NSDateFormatterStyle formatterStyles[] = {
    NSDateFormatterShortStyle,
    NSDateFormatterMediumStyle,
    NSDateFormatterLongStyle,
    NSDateFormatterFullStyle,
    NSDateFormatterNoStyle
};

// note: these formats must be 0-padded where appropriate and contain no spaces
// or attempts to force them into strict interpretation will fail
static const NSString *timeFormats[] = {
    @"hha",
    @"HHmmss",
    @"HHmm",
    @"HH",
    nil
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
    
    for (const NSDateFormatterStyle *s = formatterStyles ; *s != NSDateFormatterNoStyle ; *s++) {
	NSDateFormatter *tryFormatter = dateFormatterWithStyle(*s);
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
    NSDateFormatter *tryFormatter;
    
    for (const NSDateFormatterStyle *s = formatterStyles ; *s != NSDateFormatterNoStyle ; *s++) {
	tryFormatter = timeFormatterWithStyle(*s);
	[tryFormatters addObject: tryFormatter];
	[tryFormatter release];
    }
    for (NSString **s = timeFormats ; *s != nil ; *s++) {
	tryFormatter = timeFormatterWithFormat(*s);
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
    NSString *cleaned = nil;

    // don't let time specifications ending in "a" or "p" trigger Date::Manip
    if ([self timeStyle] != NSDateFormatterNoStyle &&
	[string length] > 1 &&
	![[NSCharacterSet letterCharacterSet]
	   characterIsMember: [string characterAtIndex: [string length] - 2]]) {

	NSString *am = [self AMSymbol], *pm = [self PMSymbol];
	if (am != nil && [am length] > 1 && pm != nil && [pm length] > 1) {

	    NSString *a = [am substringToIndex: 1], *p = [pm substringToIndex: 1];
	    if (![a isCaseInsensitiveLike: p]) {

		NSString *last = [string substringFromIndex: [string length] - 1];
		if ([last isCaseInsensitiveLike: a])
		    string = [string stringByAppendingString: [am substringFromIndex: 1]];
		if ([last isCaseInsensitiveLike: p])
		    string = [string stringByAppendingString: [pm substringFromIndex: 1]];
	    }
	}
    }
    
    while ( (tryFormatter = [e nextObject]) != nil) {
	date = [tryFormatter dateFromString: string];

	if (date == nil)
	    continue;

	if (([tryFormatter dateStyle] != NSDateFormatterNoStyle) ||
	    ([tryFormatter timeStyle] != NSDateFormatterNoStyle))
	    goto success;

	// XXX ICU-based "format" formatters return 0 instead of nil
	if ([date timeIntervalSince1970] == 0)
	    continue;

	// even non-lenient ICU-based "format" formatters are insufficiently strict,
	// permitting arbitrary characters before and after the parsed string
	NSString *formatted = [tryFormatter stringFromDate: date];
	if (cleaned == nil)
	    cleaned = [[string componentsSeparatedByString: @" "] componentsJoinedByString: @""];
	if ([cleaned characterAtIndex: 0] != '0' && [formatted characterAtIndex: 0] == '0')
	    formatted = [formatted substringFromIndex: 1];

	if ([formatted isCaseInsensitiveLike: cleaned])
	    goto success;
    }
    
    if (parse_natural_language_date == NULL) return NO;

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
