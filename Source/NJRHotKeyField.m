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

@implementation NJRHotKeyField

const NSRange zeroRange = {0, 0};
static NSParagraphStyle *leftAlignStyle = nil, *centerAlignStyle = nil;
static NSDictionary *statusAttributes = nil;

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
    NSMutableAttributedString *equivString = [[hotKeyCharacters keyEquivalentAttributedStringWithModifierMask: hotKeyModifierFlags] mutableCopy];
    [equivString addAttribute: NSParagraphStyleAttributeName
                        value: (finalized ? centerAlignStyle : leftAlignStyle)
                        range: NSMakeRange(0, [equivString length])];
    [self setAttributedStringValue: equivString];
    [[self currentEditor] setSelectedRange: zeroRange];
    [equivString release];
}

- (void)setHotKeyEvent:(NSEvent *)theEvent;
{
    [hotKeyCharacters release]; hotKeyCharacters = [[theEvent charactersIgnoringModifiers] retain];
    hotKeyModifierFlags = [theEvent modifierFlags];
    hotKeyCode = [theEvent keyCode];
}

- (void)keyUp:(NSEvent *)theEvent;
{
    NSString *characters = [theEvent charactersIgnoringModifiers];
    if ([characters length] > 1) {
        [self showStatus: @"please press only one non-modifier key"];
        return;
    }
    // Yay, we can ask for keyCode, which is likely to be the same as Carbon's, I hope.
    [self setHotKeyEvent: theEvent];

    [self showKeyEquivalentAttributedStringFinalized: ([theEvent modifierFlags] == 0)];
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
{
    [self keyUp: theEvent];
    return [super performKeyEquivalent: theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent;
{
    unsigned modifierFlags = [theEvent modifierFlags];

    // XXX why does my API call it a modifier mask when NSEvent's API calls it modifier flags? Check HostLauncher for usage.

    if (modifierFlags == 0) {
        [self showKeyEquivalentAttributedStringFinalized: YES];
    } else {
        [self previewKeyEquivalentAttributedString:
            [@"" keyEquivalentAttributedStringWithModifierMask: modifierFlags]];
    }
}

- (IBAction)clear:(id)sender;
{
    [hotKeyCharacters release]; hotKeyCharacters = 0;
    hotKeyModifierFlags = 0;
    hotKeyCode = 0;
    [self showKeyEquivalentAttributedStringFinalized: YES];
}

@end
