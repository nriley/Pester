//
//  NJRHotKeyField.h
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRHotKeyField : NSTextField {
    NSString *hotKeyCharacters;
    unsigned hotKeyModifierFlags;
    unsigned short hotKeyCode;
}

- (IBAction)clear:(id)sender;

- (NSDictionary *)propertyListRepresentation;
- (void)setFromPropertyList:(NSDictionary *)dict;

@end

@interface NSObject (NJRHotKeyFieldDelegate)

- (BOOL)hotKeyField:(NJRHotKeyField *)hotKeyField shouldAcceptCharacter:(unichar)keyChar modifierFlags:(unsigned)modifierFlags rejectionMessage:(NSString **)message;

@end