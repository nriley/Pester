//
//  NJRHotKey.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 01 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRHotKey.h"
#import "NSString-NJRExtensions.h"

#include <Carbon/Carbon.h>

// property list keys
static NSString * const PLCharacters = @"characters"; // NSString
static NSString * const PLModifierFlags = @"modifierFlags"; // NSNumber
static NSString * const PLKeyCode = @"keyCode"; // NSNumber

@implementation NJRHotKey

#pragma mark initialize-release

+ (NJRHotKey *)hotKeyWithCharacters:(NSString *)characters modifierFlags:(unsigned)modifierFlags keyCode:(unsigned short)keyCode;
{
    return [[[self alloc] initWithCharacters: characters modifierFlags: modifierFlags keyCode: keyCode] autorelease];
}

- (id)initWithCharacters:(NSString *)characters modifierFlags:(unsigned)modifierFlags keyCode:(unsigned short)keyCode;
{
    if ( (self = [self init]) != nil) {
        hotKeyCharacters = [characters retain];
        hotKeyModifierFlags = modifierFlags;
        hotKeyCode = keyCode;
    }
    return self;
}

- (void)dealloc;
{
    [hotKeyCharacters release];
}

#pragma mark accessing

- (NSString *)characters;
{
    return hotKeyCharacters;
}

- (unsigned)modifierFlags;
{
    return hotKeyModifierFlags;
}

- (long)modifiers;
{
    static long modifierMap[5][2] = {
       { NSCommandKeyMask, cmdKey },
       { NSAlternateKeyMask, optionKey },
       { NSControlKeyMask, controlKey },
       { NSShiftKeyMask, shiftKey },
       { 0, 0 }
    };

    long modifiers = 0;
    int i;

    for (i = 0 ; modifierMap[i][0] != 0 ; i++)
        if (hotKeyModifierFlags & modifierMap[i][0])
            modifiers |= modifierMap[i][1];

    return modifiers;
}

- (unsigned short)keyCode;
{
    return hotKeyCode;
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        hotKeyCharacters, PLCharacters,
        [NSNumber numberWithUnsignedInt: hotKeyModifierFlags], PLModifierFlags,
        [NSNumber numberWithUnsignedShort: hotKeyCode], PLKeyCode,
        nil];
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self init]) != nil) {
        NS_DURING
            hotKeyCharacters = [[dict objectForKey: PLCharacters] retain];
            hotKeyModifierFlags = [[dict objectForKey: PLModifierFlags] unsignedIntValue];
            hotKeyCode = [[dict objectForKey: PLKeyCode] unsignedShortValue];
        NS_HANDLER
        NS_ENDHANDLER
        if (hotKeyCharacters == nil || hotKeyCode == 0) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (NSString *)keyGlyphs;
{
    return [[hotKeyCharacters keyEquivalentAttributedStringWithModifierFlags: hotKeyModifierFlags] string];
}

@end
