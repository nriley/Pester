//
//  NJRHotKeyField.h
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NJRHotKey;

@interface NJRHotKeyField : NSTextField {
    NJRHotKey *hotKey;
}

- (NJRHotKey *)hotKey;
- (void)setHotKey:(NJRHotKey *)aKey;

- (IBAction)clear:(id)sender;

@end

@interface NSObject (NJRHotKeyFieldDelegate)

- (BOOL)hotKeyField:(NJRHotKeyField *)hotKeyField shouldAcceptCharacter:(unichar)keyChar modifierFlags:(unsigned)modifierFlags rejectionMessage:(NSString **)message;

@end