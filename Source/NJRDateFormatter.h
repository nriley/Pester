//
//  NJRDateFormatter.h
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>

// posted when the availability or output of the natural language date parser changes (after async initialization at launch; new system time zone; new system locale may change the parser's availability)
extern NSString * const NJRDateFormatterNaturalLanguageDateParsingDidChangeNotification;

@interface NJRDateFormatter : NSDateFormatter {
    NSArray *tryFormatters;
}

+ (BOOL)naturalLanguageParsingAvailable;
+ (NJRDateFormatter *)dateFormatter;
+ (NJRDateFormatter *)timeFormatter;

@end
