//
//  NSString-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Mon Dec 16 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSString-NJRExtensions.h"

@implementation NSString (NJRExtensions)

- (NSAttributedString *)attributedStringWithFont:(NSFont *)font;
{
    return [[[NSAttributedString alloc] initWithString: self attributes: [NSDictionary dictionaryWithObject: font forKey: NSFontAttributeName]] autorelease];
}

- (NSAttributedString *)underlined;
{
    return [[[NSAttributedString alloc] initWithString: self attributes: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: NSSingleUnderlineStyle] forKey: NSUnderlineStyleAttributeName]] autorelease];
}

- (NSAttributedString *)small;
{
    return [self attributedStringWithFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
}

- (NSAttributedString *)smallBold;
{
    return [self attributedStringWithFont: [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]]];
}

+ (NSString *)ellipsisString;
{
    static NSString *ellipsis = nil;
    if (ellipsis == nil) {
        const unichar ellipsisChar = 0x2026;
        ellipsis = [[NSString alloc] initWithCharacters: &ellipsisChar length: 1];
    }
    return ellipsis;
}

@end

@implementation NSMutableString (NJRExtensions)

- (void)truncateToLength:(unsigned)maxLength by:(NSLineBreakMode)method;
{
    if ([self length] > maxLength) {
        NSRange range = {0, [self length] - maxLength};
        switch (method) {
            case NSLineBreakByTruncatingHead:
                range.location = 0;
                break;
            case NSLineBreakByTruncatingMiddle:
                range.location = maxLength / 2;
                break;
            case NSLineBreakByTruncatingTail:
                range.location = maxLength;
                break;
            default:
                range.location = maxLength;
                break;
        }
        [self replaceCharactersInRange: range withString: [NSString ellipsisString]];
    }
}

- (void)truncateToWidth:(float)maxWidth by:(NSLineBreakMode)method withAttributes:(NSDictionary *)attributes;
{
    if ([self sizeWithAttributes: attributes].width > maxWidth) {
        float width = maxWidth;
        int min = 0, max = [self length], avg;
        NSMutableString *original = [self mutableCopy];
        while (max >= min) {
            avg = (max + min) / 2;
            [self truncateToLength: avg by: method];
            width = [self sizeWithAttributes: attributes].width;
            if (width > maxWidth) {
                max = avg - 1; // too wide
            } else if (width == maxWidth) {
                break;
            } else {
                min = avg + 1; // too narrow
                [self setString: original];
            }
        }
        if (width != maxWidth)
            [self truncateToLength: max by: method];
        [original release];
    }
}

@end
