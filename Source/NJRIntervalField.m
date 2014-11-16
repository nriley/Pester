//
//  NJRIntervalField.m
//  Pester
//
//  Created by Nicholas Riley on Wed Dec 25 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRIntervalField.h"

@implementation NJRIntervalField

static NSDictionary *unitLabels;

+ (void)initialize;
{
    unitLabels = [[NSDictionary dictionaryWithContentsOfURL: [[NSBundle mainBundle] URLForResource: @"NJRIntervalField" withExtension: @"plist"]] retain];
}

- (void)_observeTextDidChange;
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(controlTextDidChange:) name: NSControlTextDidChangeNotification object: self];
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    if ( (self = [super initWithCoder: aDecoder]) != nil)
        [self _observeTextDidChange];
    return self;
}

- (id)initWithFrame:(NSRect)frameRect;
{
    if ( (self = [super initWithFrame: frameRect]) != nil)
        [self _observeTextDidChange];
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

- (void)setIntervalUnits:(NSPopUpButton *)aPopUpButton;
{
    if (intervalUnits == aPopUpButton)
        return;

    [intervalUnits release];
    intervalUnits = [aPopUpButton retain];

    for (NSMenuItem *item in [intervalUnits itemArray]) {
        NSInteger tag = [item tag];
        if (tag == 0)
            continue;

        NSDictionary *labelsForUnit = [unitLabels objectForKey:[NSString stringWithFormat: @"%d", tag]];
        if (labelsForUnit == nil)
            continue;

        [item setRepresentedObject: labelsForUnit];
    }
}

- (NSInteger)intervalValue;
{
    NSText *editor = [self currentEditor];
    id obj = nil;

    if (editor != nil) {
        NSString *stringValue = [editor string];
        if (![[self formatter] getObjectValue: &obj forString: stringValue errorDescription: NULL])
            return 0;
    } else {
        obj = self;
    }

    return [obj integerValue];
}

- (void)_updateUnitLabels;
{
    NSString *valueString = [NSString stringWithFormat: @"%d", [self intervalValue]];

    for (NSMenuItem *item in [intervalUnits itemArray]) {
        NSDictionary *labelsForUnit = [item representedObject];
        if (labelsForUnit == nil)
            continue;

        NSString *label = [labelsForUnit objectForKey:valueString];
        if (label == nil)
            label = [labelsForUnit objectForKey:@"0"];

        if (label != nil)
            [item setTitle: label];
    }
}

- (NSTimeInterval)interval;
{
    return [self intervalValue] * [[intervalUnits selectedItem] tag];
}

- (BOOL)setInterval:(NSTimeInterval)interval;
{
    // assuming the tags are in ascending order in the array
    for (NSMenuItem *item in [[intervalUnits itemArray] reverseObjectEnumerator]) {
        NSInteger multiplierTag = [item tag];
        if (multiplierTag <= 0) continue;
        if (((NSInteger)interval % multiplierTag) == 0) {
            NSFormatter *formatter = [self formatter];
            int intervalValue = (NSInteger)interval / multiplierTag;
            if (formatter != nil) {
                id ignored;
                if (![formatter getObjectValue: &ignored forString: [formatter stringForObjectValue: [NSNumber numberWithInteger: intervalValue]] errorDescription: NULL]) return NO;
            }
            [self setIntegerValue: intervalValue];
            [intervalUnits selectItem: item];
            [self _updateUnitLabels];

            return YES;
        }
    }
    return NO;
}

- (int)intervalMultiplierTag;
{
    return [intervalUnits selectedTag];
}

- (void)setIntervalMultiplierTag:(int)tag;
{
    if (tag == 0 || ![intervalUnits selectItemWithTag: tag])
	[intervalUnits selectItemAtIndex: 0];
}

#pragma mark NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)range replacementString:(NSString *)string;
{
    unsigned length = [string length];
    if (length != 0) {
        unichar c;
        int tag = -1;
        c = [string characterAtIndex: length - 1];
        switch (c) {
            case 's': case 'S': tag = 1; break;
            case 'm': case 'M': tag = 60; break;
            case 'h': case 'H': tag = 60 * 60; break;
	    case 'd': case 'D': tag = 60 * 60 * 24; break;
	    case 'w': case 'W': tag = 60 * 60 * 24 * 7; break;
            case 'u': case 'U': tag = -2; break;
            default: break;
        }
        if (tag != -1) {
            int itemIndex = [intervalUnits indexOfItemWithTag: tag];
            if (itemIndex != -1) {
                [intervalUnits selectItemAtIndex: itemIndex];
                [[intervalUnits menu] performActionForItemAtIndex: itemIndex];
            }
            if (tag < 0) return NO; // don't send update
        }
    }
    if ([super respondsToSelector: _cmd])
        return [super textView: textView shouldChangeTextInRange: range replacementString: string];
    return YES;
}

@end

@implementation NJRIntervalField (NSControlSubclassNotifications)

- (void)controlTextDidChange:(NSNotification *)obj;
{
    [self _updateUnitLabels];
}

@end
