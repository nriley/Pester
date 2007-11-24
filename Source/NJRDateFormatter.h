//
//  NJRDateFormatter.h
//  Pester
//
//  Created by Nicholas Riley on Wed Oct 09 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NJRDateFormatter : NSDateFormatter {
    NSArray *tryFormatters;
}

+ (BOOL)naturalLanguageParsingAvailable;
+ (NJRDateFormatter *)dateFormatter;
+ (NJRDateFormatter *)timeFormatter;

@end
