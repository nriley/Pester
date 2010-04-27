//
//  NJRHotKeyField.m
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRHotKeyField.h"
#import "NJRHotKeyFieldCell.h"
#import "NJRHotKey.h"
#import "NSString-NJRExtensions.h"

static const NSRange zeroRange = {0, 0};
static const unsigned int capturedModifierMask = (NSShiftKeyMask |
                                                  NSControlKeyMask |
                                                  NSAlternateKeyMask |
                                                  NSCommandKeyMask);

static NSParagraphStyle *leftAlignStyle = nil, *centerAlignStyle = nil;
static NSDictionary *statusAttributes = nil;

@interface NJRHotKeyField (Private)
- (void)clearStatus;
@end

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

- (void)viewWillMoveToWindow:(NSWindow *)newWindow;
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver: self name: NSWindowDidResignKeyNotification object: [self window]];
    [super viewWillMoveToWindow: newWindow];
    [notificationCenter addObserver: self selector: @selector(windowDidResignKey:) name: NSWindowDidResignKeyNotification object: newWindow];
}

#pragma mark initialize-release

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

- (void)dealloc;
{
    [hotKey release];
    [super dealloc];
}

#pragma mark interface updating

- (void)showStatus:(NSString *)error;
{
    [self setAttributedStringValue:
        [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"(%@)", error]
                                        attributes: statusAttributes]];
    [NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(clearStatus) object: nil];
    [self performSelector: @selector(clearStatus) withObject: nil afterDelay: 0.5];
    [[self currentEditor] setSelectedRange: zeroRange];
}

- (void)previewKeyEquivalentAttributedString:(NSAttributedString *)equivString;
{
    NSMutableAttributedString *previewString = [equivString mutableCopy];
    [previewString addAttribute: NSParagraphStyleAttributeName value: leftAlignStyle range: NSMakeRange(0, [previewString length])];
    [self setAttributedStringValue: previewString];
    [[self currentEditor] setSelectedRange: zeroRange];
    [previewString release];
}

- (void)showKeyEquivalentAttributedStringFinalized:(BOOL)finalized;
{
    if ([hotKey characters] == nil) {
        [self showStatus: @"none assigned"];
        return;
    }
    NSMutableAttributedString *equivString = [[[hotKey characters] keyEquivalentAttributedStringWithModifierFlags: [hotKey modifierFlags]] mutableCopy];
    [equivString addAttribute: NSParagraphStyleAttributeName
                        value: (finalized ? centerAlignStyle : leftAlignStyle)
                        range: NSMakeRange(0, [equivString length])];
    [self setAttributedStringValue: equivString];
    [[self currentEditor] setSelectedRange: zeroRange];
    [equivString release];
}

- (void)clearStatus;
{
    if ([[[self attributedStringValue] attributesAtIndex: 0 effectiveRange: NULL] isEqualToDictionary: statusAttributes]) {
        [self showKeyEquivalentAttributedStringFinalized: ([[NSApp currentEvent] modifierFlags] & capturedModifierMask) == 0];
    }
}

- (void)textDidEndEditing:(NSNotification *)notification;
{
    [self showKeyEquivalentAttributedStringFinalized: YES];
    [super textDidEndEditing: notification];
}

#pragma mark event handling

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
	unichar character = [characters characterAtIndex: 0];
	if (character == NSTabCharacter || character == NSBackTabCharacter)
	    return;
        if (delegate != nil && ![delegate hotKeyField: self shouldAcceptCharacter: character modifierFlags: modifierFlags rejectionMessage: &message]) {
            [self showStatus: message != nil ? message : @"key is unavailable for use"];
        } else {
            [self setHotKey: [NJRHotKey hotKeyWithCharacters: characters modifierFlags: modifierFlags keyCode: [theEvent keyCode]]];
            [NSApp sendAction: [self action] to: [self target] from: self];
            [self showKeyEquivalentAttributedStringFinalized: ([theEvent modifierFlags] & capturedModifierMask) == 0];
        }
    }
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
{
    if ([[self window] firstResponder] == self)
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

#pragma mark acccessing

- (NJRHotKey *)hotKey;
{
    return hotKey;
}

- (void)setHotKey:(NJRHotKey *)aKey;
{
    if (aKey != hotKey) {
        [hotKey release];
        hotKey = [aKey retain];
        [self showKeyEquivalentAttributedStringFinalized: YES];
    }
}

#pragma mark actions

- (IBAction)clear:(id)sender;
{
    [self setHotKey: nil];
    [NSApp sendAction: [self action] to: [self target] from: self];
    [self showKeyEquivalentAttributedStringFinalized: YES];
}

@end

@implementation NJRHotKeyField (NSWindowNotifications)

- (void)windowDidResignKey:(NSNotification *)notification;
{
    [self showKeyEquivalentAttributedStringFinalized: YES];
}

@end