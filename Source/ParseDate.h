//
//  ParseDate.h
//  Pester
//
//  Created by Nicholas Riley on 11/28/07.
//  Copyright 2007 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>

// returns [NSDate distantPast] if parser is unavailable
NSDate *(*parse_natural_language_date)(NSString *) = NULL;

// update parser with current locale/time zone information (may make available)
void (*init_date_parser)(void) = NULL;
