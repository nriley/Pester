//
//  NJRHotKey.h
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 01 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NJRHotKey : NSObject {
    NSString *hotKeyCharacters;
    unsigned hotKeyModifierFlags;
    unsigned short hotKeyCode;
}

+ (NJRHotKey *)hotKeyWithCharacters:(NSString *)characters modifierFlags:(unsigned)modifierFlags keyCode:(unsigned short)keyCode;

- (id)initWithCharacters:(NSString *)characters modifierFlags:(unsigned)modifierFlags keyCode:(unsigned short)keyCode;

- (NSString *)characters;
- (unsigned)modifierFlags; // Cocoa
- (long)modifiers; // Carbon
- (unsigned short)keyCode;

- (NSDictionary *)propertyListRepresentation;
- (id)initWithPropertyList:(NSDictionary *)dict;

- (NSString *)keyGlyphs;

@end
