//
//  ParseDate.h
//  Pester
//
//  Created by Nicholas Riley on 11/28/07.
//  Copyright 2007 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>

// returns [NSDate distantPast] if failed to initialize
NSDate *(*parse_natural_language_date)(NSString *) = NULL;
