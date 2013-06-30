//
//  NJRIntervalField.m
//  Pester
//
//  Created by Nicholas Riley on Wed Dec 25 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRIntervalField.h"

// XXX much implementation borrowed from DockCam, then factored; should replace DockCam interval selector with a NJRIntervalField at some point

@implementation NJRIntervalField

- (NSTimeInterval)interval;
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
    
    return [obj intValue] * [[intervalUnits selectedItem] tag];
}

- (BOOL)setInterval:(NSTimeInterval)interval;
{
    // we assume that the tags are in ascending order in the array
    NSEnumerator *e = [[intervalUnits itemArray] reverseObjectEnumerator];
    NSMenuItem *i;
    int multiplierTag;

    while ( (i = [e nextObject]) != nil) {
        multiplierTag = [i tag];
        if (multiplierTag <= 0) continue;
        if (((int)interval % multiplierTag) == 0) {
            NSFormatter *formatter = [self formatter];
            int intervalValue = (int)interval / multiplierTag;
            if (formatter != nil) {
                id ignored;
                if (![formatter getObjectValue: &ignored forString: [formatter stringForObjectValue: [NSNumber numberWithInt: intervalValue]] errorDescription: NULL]) return NO;
            }
            [self setIntValue: intervalValue];
            [intervalUnits selectItem: i];
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
