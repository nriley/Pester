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
    [super dealloc];
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

- (UInt16)modifiers;
{
    static NSUInteger modifierMap[5][2] = {
        { NSEventModifierFlagCommand, cmdKey },
        { NSEventModifierFlagOption, optionKey },
        { NSEventModifierFlagControl, controlKey },
        { NSEventModifierFlagShift, shiftKey },
        { 0, 0 }
    };

    UInt16 modifiers = 0;

    for (NSUInteger i = 0 ; modifierMap[i][0] != 0 ; i++)
        if (hotKeyModifierFlags & modifierMap[i][0])
            modifiers |= (UInt16)modifierMap[i][1];

    return modifiers;
}

- (unsigned short)keyCode;
{
    return hotKeyCode;
}

- (NSString *)keyGlyphs;
{
    return [[hotKeyCharacters keyEquivalentAttributedStringWithModifierFlags: hotKeyModifierFlags] string];
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

- (instancetype)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self init]) != nil) {
        hotKeyCode = 0xFFFF;
	@try {
            hotKeyCharacters = [[dict objectForKey: PLCharacters] retain];
            hotKeyModifierFlags = [[dict objectForKey: PLModifierFlags] unsignedIntValue];
            hotKeyCode = [[dict objectForKey: PLKeyCode] unsignedShortValue];
	} @catch (NSException *exception) {
	}
        if (hotKeyCharacters == nil || hotKeyCode == 0xFFFF) {
            [self release];
            self = nil;
        }
    }
    return self;
}

@end
