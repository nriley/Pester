//
//  NSString-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on Mon Dec 16 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NSString (NJRExtensions)

- (NSAttributedString *)small;
- (NSAttributedString *)smallBold;
- (NSAttributedString *)underlined;

+ (NSString *)ellipsisString;


@end

@interface NSMutableString (NJRExtensions)

- (void)truncateToLength:(unsigned)maxLength by:(NSLineBreakMode)method;
- (void)truncateToWidth:(float)maxWidth by:(NSLineBreakMode)method withAttributes:(NSDictionary *)attributes;

@end