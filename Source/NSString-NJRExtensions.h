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

- (NSAttributedString *)keyEquivalentAttributedStringWithModifierFlags:(unsigned int)modifierFlags;

- (NSAttributedString *)attributedStringByPrependingFontAwesomeIcon:(NSString *)icon inCell:(NSCell *)cell;

@end

@interface NSMutableString (NJRExtensions)

- (void)truncateToWidth:(float)maxWidth by:(NSLineBreakMode)method withAttributes:(NSDictionary *)attributes;

@end