//
//  NJRHotKeyManager.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 01 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

// based on HotKeyCenter, by Quentin Carnicelli
// renamed, reorganized, cleaned up, pre-10.2 support removed

#import "NJRHotKeyManager.h"
#import "NJRHotKey.h"
#import <Carbon/Carbon.h>

@interface _NJRHotKeyShortcut : NSObject {
    @public
    BOOL isRegistered;
    EventHotKeyRef hotKeyRef;
    NJRHotKey *hotKey;
    id target;
    SEL action;
}
@end

@implementation _NJRHotKeyShortcut

- (void)dealloc;
{
    [hotKey release];
    [target release];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"<%@: %@ %sregistered [%@ %@]>", [self className], [hotKey keyGlyphs],
	     isRegistered ? "" : "not ", target, NSStringFromSelector(action)];
}

@end

pascal OSErr keyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon);

@interface NJRHotKeyManager (Private)
- (OSStatus)_handleHotKeyEvent:(EventRef)inEvent;
- (BOOL)_registerHotKeyIfNeeded:(_NJRHotKeyShortcut *)shortcut;
- (void)_unregisterHotKeyIfNeeded:(_NJRHotKeyShortcut *)shortcut;
- (void)_hotKeyDown:(_NJRHotKeyShortcut *)hotKey;
- (void)_hotKeyUp:(_NJRHotKeyShortcut *)hotKey;
- (void)_hotKeyDownWithRef:(EventHotKeyRef)ref;
- (void)_hotKeyUpWithRef:(EventHotKeyRef)ref;
- (_NJRHotKeyShortcut *)_findShortcutWithRef:(EventHotKeyRef)ref;
@end

@implementation NJRHotKeyManager

+ (NJRHotKeyManager *)sharedManager;
{
    static NJRHotKeyManager *manager = nil;

    if (manager == nil) {
        manager = [[self alloc] init];

        EventTypeSpec eventSpec[2] = {
           { kEventClassKeyboard, kEventHotKeyPressed },
           { kEventClassKeyboard, kEventHotKeyReleased }
        };

        InstallEventHandler(GetEventDispatcherTarget(),
                            NewEventHandlerUPP((EventHandlerProcPtr) keyEventHandler),
                            2, eventSpec, nil, nil);
    }
    return manager;
}

- (id)init;
{
    if ( (self = [super init]) != nil) {
        shortcutsEnabled = YES;
        shortcuts = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc;
{
    [shortcuts release];
    [super dealloc];
}

#pragma mark -

- (BOOL)addShortcutWithIdentifier:(NSString *)identifier hotKey:(NJRHotKey *)hotKey target:(id)target action:(SEL)action;
{
    NSParameterAssert(identifier != nil);
    NSParameterAssert(hotKey != nil);
    NSParameterAssert(target != nil);
    NSParameterAssert(action != nil);

    if ([shortcuts objectForKey: identifier] != nil)
        [self removeShortcutWithIdentifier: identifier];

    _NJRHotKeyShortcut *newShortcut = [[_NJRHotKeyShortcut alloc] init];
    newShortcut->isRegistered = NO;
    newShortcut->hotKeyRef = nil;
    newShortcut->hotKey = [hotKey retain];
    newShortcut->target = [target retain];
    newShortcut->action = action;

    [shortcuts setObject: newShortcut forKey: identifier];
    [newShortcut release];

    return [self _registerHotKeyIfNeeded: newShortcut];
}

- (void)removeShortcutWithIdentifier:(NSString *)identifier;
{
    _NJRHotKeyShortcut *hotKey = [shortcuts objectForKey: identifier];

    if (hotKey == nil) return;
    [self _unregisterHotKeyIfNeeded: hotKey];
    [shortcuts removeObjectForKey: identifier];
}

- (NSArray *)shortcutIdentifiers;
{
    return [shortcuts allKeys];
}

- (NJRHotKey *)hotKeyForShortcutWithIdentifier:(NSString *)identifier;
{
    _NJRHotKeyShortcut *hotKey = [shortcuts objectForKey: identifier];

    return (hotKey == nil ? nil : [[hotKey->hotKey retain] autorelease]);
}

- (BOOL)hotKeyInUseWithCode:(NSInteger)keyCode modifierFlags:(NSUInteger)modifierFlags;
{
    NSEnumerator *enumerator = [shortcuts objectEnumerator];
    _NJRHotKeyShortcut *hotKey;

    while ( (hotKey = [enumerator nextObject]) != nil) {
        if ([hotKey->hotKey keyCode] == keyCode && [hotKey->hotKey modifierFlags] == modifierFlags)
            return YES;
    }
    return NO;
}

- (void)setShortcutsEnabled:(BOOL)enabled;
{
    if (enabled == shortcutsEnabled)
	return;

    shortcutsEnabled = enabled;

    NSEnumerator *enumerator = [shortcuts objectEnumerator];
    _NJRHotKeyShortcut *hotKey;

    while ( (hotKey = [enumerator nextObject]) != nil) {
        if (enabled)
            [self _registerHotKeyIfNeeded: hotKey];
        else
            [self _unregisterHotKeyIfNeeded: hotKey];
    }
}

- (BOOL)shortcutsEnabled;
{
    return shortcutsEnabled;
}

#pragma mark -

- (OSStatus)_handleHotKeyEvent:(EventRef)inEvent;
{
    OSStatus err;
    EventHotKeyID hotKeyID;
    _NJRHotKeyShortcut *shortcut;

    NSAssert(GetEventClass(inEvent) == kEventClassKeyboard, @"Unhandled event class");

    if ( (err = GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, nil,
                                  sizeof(EventHotKeyID), nil, &hotKeyID)) != noErr)
        return err;

    shortcut = (_NJRHotKeyShortcut *)((NSUInteger)hotKeyID.signature << 32 | (NSUInteger)hotKeyID.id);
    NSAssert(shortcut != nil, @"Got bad hot key");

    switch (GetEventKind(inEvent)) {
        case kEventHotKeyPressed:
            [self _hotKeyDown: shortcut];
            break;
        case kEventHotKeyReleased:
            [self _hotKeyUp: shortcut];
            break;
        default:
            break;
    }

    return noErr;
}

#pragma mark -

- (BOOL)_registerHotKeyIfNeeded:(_NJRHotKeyShortcut *)shortcut;
{
    NJRHotKey *hotKey;

    NSParameterAssert(shortcut != nil);

    hotKey = shortcut->hotKey;

    if (shortcutsEnabled && !(shortcut->isRegistered)) {
        EventHotKeyID keyID;

        keyID.signature = (NSUInteger)shortcut >> 32;
        keyID.id = (UInt32)shortcut;

        if (RegisterEventHotKey([hotKey keyCode], [hotKey modifiers], keyID, GetEventDispatcherTarget(), kEventHotKeyExclusive, &shortcut->hotKeyRef) != noErr)
            return NO;

        shortcut->isRegistered = YES;
    }

    return YES;
}

- (void)_unregisterHotKeyIfNeeded:(_NJRHotKeyShortcut *)shortcut;
{
    NSParameterAssert(shortcut != nil);

    if (shortcut->isRegistered && shortcut->hotKeyRef != nil) {
        UnregisterEventHotKey(shortcut->hotKeyRef);
	shortcut->isRegistered = NO;
    }
}

- (void)_hotKeyDown:(_NJRHotKeyShortcut *)hotKey;
{
    id target = hotKey->target;
    SEL action = hotKey->action;

    [target performSelector: action withObject: self];
}

- (void)_hotKeyUp:(_NJRHotKeyShortcut *)hotKey;
{
}

- (void)_hotKeyDownWithRef:(EventHotKeyRef)ref;
{
    _NJRHotKeyShortcut *hotKey = [self _findShortcutWithRef: ref];

    if (hotKey != nil)
        [self _hotKeyDown: hotKey];
}

- (void)_hotKeyUpWithRef:(EventHotKeyRef)ref;
{
}

- (_NJRHotKeyShortcut *)_findShortcutWithRef:(EventHotKeyRef)ref;
{
    NSEnumerator *enumerator = [shortcuts objectEnumerator];
    _NJRHotKeyShortcut *hotKey;

    while ( (hotKey = [enumerator nextObject]) != nil) {
        if (hotKey->hotKeyRef == ref)
            return hotKey;
    }
    return nil;
}

@end

pascal OSErr keyEventHandler(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *refCon)
{
    return [[NJRHotKeyManager sharedManager] _handleHotKeyEvent: inEvent];
}
