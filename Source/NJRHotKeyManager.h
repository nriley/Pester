//
//  NJRHotKeyManager.h
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 01 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NJRHotKey;

@interface NJRHotKeyManager : NSObject {
    BOOL shortcutsEnabled;
    NSMutableDictionary *shortcuts;
}

+ (NJRHotKeyManager *)sharedManager;

- (BOOL)addShortcutWithIdentifier:(NSString *)identifier hotKey:(NJRHotKey *)hotKey target:(id)target action:(SEL)action;
- (void)removeShortcutWithIdentifier:(NSString *)identifier;

- (NSArray *)shortcutIdentifiers;
- (NJRHotKey *)hotKeyForShortcutWithIdentifier:(NSString *)identifier;

- (void)setShortcutsEnabled:(BOOL)enabled;
- (BOOL)shortcutsEnabled;


@end
