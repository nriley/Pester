//
//  NJRHotKeyField.m
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRHotKeyField.h"
#import "NJRHotKeyFieldCell.h"
#import "NSString-NJRExtensions.h"

// property list keys
static NSString * const PLCharacters = @"characters"; // NSString
static NSString * const PLModifierFlags = @"modifierFlags"; // NSNumber
static NSString * const PLKeyCode = @"keyCode"; // NSNumber

static const NSRange zeroRange = {0, 0};
static const unsigned int capturedModifierMask = (NSShiftKeyMask |
                                                  NSControlKeyMask |
                                                  NSAlternateKeyMask |
                                                  NSCommandKeyMask);

static NSParagraphStyle *leftAlignStyle = nil, *centerAlignStyle = nil;
static NSDictionary *statusAttributes = nil;

@implementation NJRHotKeyField

+ (void)initialize;
{
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment: NSLeftTextAlignment];
    leftAlignStyle = [paraStyle copy];
    [paraStyle setAlignment: NSCenterTextAlignment];
    centerAlignStyle = [paraStyle copy];
    [paraStyle release];

    statusAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
        [NSFont systemFontOfSize: [NSFont labelFontSize]], NSFontAttributeName,
        centerAlignStyle, NSParagraphStyleAttributeName, nil];
}

- (void)_setUp;
{
    [self setAllowsEditingTextAttributes: YES];
    [self setImportsGraphics: NO];
    [self cell]->isa = [NJRHotKeyFieldCell class];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if ( (self = [super initWithCoder: coder]) != nil) {
        [self _setUp];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect;
{
    if ( (self = [super initWithFrame: frameRect]) != nil) {
        [self _setUp];
    }
    return self;
}

// XXX still problems with command-A the first time

- (void)previewKeyEquivalentAttributedString:(NSAttributedString *)equivString;
{
    NSMutableAttributedString *previewString = [equivString mutableCopy];
    [previewString addAttribute: NSParagraphStyleAttributeName value: leftAlignStyle range: NSMakeRange(0, [previewString length])];
    [self setAttributedStringValue: previewString];
    [[self currentEditor] setSelectedRange: zeroRange];
    [previewString release];
}

- (void)showStatus:(NSString *)error;
{
    [self setAttributedStringValue:
        [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"(%@)", error]
                                        attributes: statusAttributes]];
    [[self currentEditor] setSelectedRange: zeroRange];
}

- (void)showKeyEquivalentAttributedStringFinalized:(BOOL)finalized;
{
    if (hotKeyCharacters == nil) {
        [self showStatus: @"none assigned"];
        return;
    }
    NSMutableAttributedString *equivString = [[hotKeyCharacters keyEquivalentAttributedStringWithModifierFlags: hotKeyModifierFlags] mutableCopy];
    [equivString addAttribute: NSParagraphStyleAttributeName
                        value: (finalized ? centerAlignStyle : leftAlignStyle)
                        range: NSMakeRange(0, [equivString length])];
    [self setAttributedStringValue: equivString];
    [[self currentEditor] setSelectedRange: zeroRange];
    [equivString release];
}

- (void)clearHotKey;
{
    [hotKeyCharacters release];
    hotKeyCharacters = nil;
    hotKeyModifierFlags = 0;
    hotKeyCode = 0;
    [NSApp sendAction: [self action] to: [self target] from: self];
}

- (void)keyUp:(NSEvent *)theEvent;
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    int length = [characters length];
    if (length > 1) {
        [self showStatus: @"please press only one non-modifier key"];
        return;
    }
    if (length == 1) {
        unsigned modifierFlags = ([theEvent modifierFlags] & capturedModifierMask);
        id delegate = [self delegate];
        NSString *message = nil;
        if (delegate != nil && ![delegate hotKeyField: self shouldAcceptCharacter: [characters characterAtIndex: 0] modifierFlags: modifierFlags rejectionMessage: &message]) {
            [self showStatus: message != nil ? message : @"key is unavailable for use"];
        } else {
            [hotKeyCharacters release];
            hotKeyCharacters = [characters retain];
            hotKeyModifierFlags = modifierFlags;
            hotKeyCode = [theEvent keyCode];
            [NSApp sendAction: [self action] to: [self target] from: self];
            [self showKeyEquivalentAttributedStringFinalized: ([theEvent modifierFlags] & capturedModifierMask) == 0];
        }
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
{
    [self keyUp: theEvent];
    return [super performKeyEquivalent: theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent;
{
    unsigned modifierFlags = [theEvent modifierFlags];

    if ((modifierFlags & capturedModifierMask) == 0) {
        [self showKeyEquivalentAttributedStringFinalized: YES];
    } else {
        [self previewKeyEquivalentAttributedString:
            [@"" keyEquivalentAttributedStringWithModifierFlags: modifierFlags]];
    }
}

- (IBAction)clear:(id)sender;
{
    [self clearHotKey];
    [self showKeyEquivalentAttributedStringFinalized: YES];
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

- (void)setFromPropertyList:(NSDictionary *)dict;
{
    NS_DURING
        hotKeyCharacters = [[dict objectForKey: PLCharacters] retain];
        hotKeyModifierFlags = [[dict objectForKey: PLModifierFlags] unsignedIntValue];
        hotKeyCode = [[dict objectForKey: PLKeyCode] unsignedShortValue];
        [self showKeyEquivalentAttributedStringFinalized: ([[NSApp currentEvent] modifierFlags] & capturedModifierMask) == 0];
    NS_HANDLER
        [self clear: nil];
    NS_ENDHANDLER
}

@end
