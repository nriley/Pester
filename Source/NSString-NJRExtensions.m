//
//  NSString-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Mon Dec 16 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NSString-NJRExtensions.h"
#include <Carbon/Carbon.h>

@implementation NSString (NJRExtensions)

+ (NSString *)stringWithCharacter:(unichar)character;
{
    return [self stringWithCharacters: &character length: 1];
}

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

static unichar combiningHelpChar[] = {0x003F, 0x20DD};

- (NSString *)keyEquivalentString;
{
    if ([self length] != 0) {
        const char *str = [self UTF8String];
        unichar keyChar;
        if (str[1] != '\0') {
            keyChar = [self characterAtIndex: 0];
            switch (keyChar) {
                case NSUpArrowFunctionKey: keyChar = 0x21E1; break;
                case NSDownArrowFunctionKey: keyChar = 0x21E3; break;
                case NSLeftArrowFunctionKey: keyChar = 0x21E0; break;
                case NSRightArrowFunctionKey: keyChar = 0x21E2; break;
                case NSInsertFunctionKey:
                    return [NSString stringWithCharacters: combiningHelpChar length: 2];
                case NSDeleteFunctionKey: keyChar = 0x2326; break;
                case NSHomeFunctionKey: keyChar = 0x2196; break;
                case NSEndFunctionKey: keyChar = 0x2198; break;
                case NSPageUpFunctionKey: keyChar = 0x21DE; break;
                case NSPageDownFunctionKey: keyChar = 0x21DF; break;
                case NSClearLineFunctionKey: keyChar = 0x2327; break;
                default:
                if (keyChar >= NSF1FunctionKey && keyChar <= NSF35FunctionKey) {
                    return [NSString stringWithFormat: @"F%u", keyChar - NSF1FunctionKey + 1];
                }
                return [NSString stringWithFormat: @"[unknown %lX]", keyChar];
            }
        } else if (str[0] >= 'A' && str[0] <= 'Z') {
            return self;
        } else if (str[0] >= 'a' && str[0] <= 'z') return [self uppercaseString];
        else switch (str[0]) {
            case '\t': keyChar = 0x21e5; break;
            case '\r': keyChar = 0x21a9; break;
            case '\e': keyChar = 0x238b; break;
            case ' ': keyChar = 0x2423; break;
            case 0x7f: keyChar = 0x232b; break; // delete
            case 0x03: keyChar = 0x2324; break; // enter
            case 0x19: keyChar = 0x21e4; break; // backtab
            case 0: return @"";
            // case '': keyChar = 0x; break;
            default: return self; // return [NSString stringWithFormat: @"[huh? %x]", (int)str[0]]; // 
        }
        return [NSString stringWithCharacter: keyChar];
    }
    return self;
}

- (NSAttributedString *)keyEquivalentAttributedStringWithModifierFlags:(unsigned int)modifierFlags;
{
    static NSFont *menuItemFont = nil;
    if (menuItemFont == nil)
        menuItemFont = [NSFont menuBarFontOfSize: 0];
    NSString *keyEquivalentStringNoMask = [self keyEquivalentString];
    NSAttributedString *keyEquivalentAttributedString =
        [[NSString stringWithFormat: @"%@%@%@%@%@",
            (modifierFlags & NSControlKeyMask) ? [NSString stringWithCharacter: kControlUnicode] : @"",
            (modifierFlags & NSAlternateKeyMask) ? [NSString stringWithCharacter: kOptionUnicode] : @"",
            (modifierFlags & NSShiftKeyMask) ? [NSString stringWithCharacter: kShiftUnicode] : @"",
            (modifierFlags & NSCommandKeyMask) ? [NSString stringWithCharacter: kCommandUnicode] : @"",
                keyEquivalentStringNoMask]
        attributedStringWithFont: menuItemFont];
    unsigned noMaskLength = [keyEquivalentStringNoMask length];
    if (noMaskLength > 3 || // Fxx
        (noMaskLength == 1 && [keyEquivalentStringNoMask characterAtIndex: 0] <= 0x7F)) {
        NSMutableAttributedString *astr = [keyEquivalentAttributedString mutableCopy];
        [astr setAttributes: [NSDictionary dictionaryWithObject: menuItemFont forKey: NSFontAttributeName] range: NSMakeRange([astr length] - noMaskLength, noMaskLength)];
        keyEquivalentAttributedString = [[astr copy] autorelease];
        [astr release];
    }
    return keyEquivalentAttributedString;
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
