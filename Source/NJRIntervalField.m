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
        if (((int)interval % multiplierTag) == 0) {
            NSFormatter *formatter = [self formatter];
            int intervalValue = interval / multiplierTag;
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
            default: break;
        }
        if (tag != -1) [intervalUnits selectItemAtIndex: [intervalUnits indexOfItemWithTag: tag]];
    }
    return [super textView: textView shouldChangeTextInRange: range replacementString: string];
}

- (void)handleDidFailToFormatString:(NSString *)string errorDescription:(NSString *)error label:(NSString *)label;
{
    NSString *alertMessage;
    NSString *alternateButtonString;
    NSDecimalNumber *proposedValue;
    NSDictionary *contextInfo;

    NSString *alertInformation = [NSString localizedStringWithFormat:
        NSLocalizedString(@"The %@ field must be set to a value between %@ and %@.",
                          @"Informative text for alert posed by text field when invalid value entered"),
        label, [[self formatter] minimum], [[self formatter] maximum]];
    NSString *defaultButtonString = NSLocalizedString(@"Edit", @"Name of Edit button");
    NSString *otherButtonString = NSLocalizedString(@"Cancel", @"Name of Cancel button");

    if ([error isEqualToString:
        NSLocalizedStringFromTableInBundle(@"Fell short of minimum", @"Formatter",
                                           [NSBundle bundleForClass:[NSFormatter class]],
                                           @"Presented when user value smaller than minimum")]) {
        proposedValue = [[self formatter] minimum];
        alertMessage = [NSString stringWithFormat:
            NSLocalizedString(@"Ò%@Ó is too small for the %@ field.",
                              @"Message text for alert posed by numeric field when too-small value entered"),
            string, label];
        alternateButtonString = [NSString localizedStringWithFormat:
            NSLocalizedString(@"Set to %@",
                              @"Name of alternate button for alert posed by numeric field when too-small value entered"),
            proposedValue];
    } else if ([error isEqualToString:
        NSLocalizedStringFromTableInBundle(@"Maximum exceeded", @"Formatter",
                                           [NSBundle bundleForClass:[NSFormatter class]],
                                           @"Presented when user value larger than maximum")]) {
        proposedValue = [[self formatter] maximum];
        alertMessage = [NSString stringWithFormat:
            NSLocalizedString(@"Ò%@Ó is too large for the %@ field.",
                              @"Message text for alert posed by numeric field when too-large value entered"),
            string, label];
        alternateButtonString = [NSString localizedStringWithFormat:
            NSLocalizedString(@"Set to %@",
                              @"Name of alternate button for alert posed by numeric field when too-large value entered"),
            proposedValue];
    } else if ([error isEqualToString:
        NSLocalizedStringFromTableInBundle(@"Invalid number", @"Formatter",
                                           [NSBundle bundleForClass:[NSFormatter class]],
                                           @"Presented when user typed illegal characters: no valid object")]) {
        alertMessage = [NSString stringWithFormat:
            NSLocalizedString(@"Ò%@Ó is not a valid entry for the %@ field.",
                              @"Message text for alert posed by text field when invalid value entered"),
            string, label];
        alternateButtonString = nil;
    }

    contextInfo = [NSDictionary dictionaryWithObject: proposedValue forKey: @"proposedValue"];
    [contextInfo retain];
    NSBeep();
    NSBeginAlertSheet(alertMessage, defaultButtonString, alternateButtonString, otherButtonString, [self window],
                      self, @selector(validationFailedSheetDidEnd:returnCode:contextInfo:), NULL, contextInfo,
                      alertInformation);
}

- (void)_propagateValidationChange;
{
    NSText *fieldEditor = [self currentEditor];
    NSDictionary *userInfo = nil;
    if (fieldEditor != nil) userInfo = [NSDictionary dictionaryWithObject: fieldEditor forKey: @"NSFieldEditor"];
    [[NSNotificationCenter defaultCenter] postNotificationName: NSControlTextDidChangeNotification object: self userInfo: userInfo];
    [self selectText: self];
}

- (void)validationFailedSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    // modal delegate callback method for NSBeginAlertSheet() function; called in the above method
    if (returnCode == NSAlertOtherReturn) { // cancel
        [self abortEditing]; // abort edit session and reinstate original value
        [self _propagateValidationChange];
    } else if (returnCode == NSAlertAlternateReturn) { // set to min/max/default value
        [self setObjectValue: [(NSDictionary *)contextInfo objectForKey: @"proposedValue"]];
        [self validateEditing];
        [self _propagateValidationChange];
    }
    [(NSDictionary *)contextInfo release];
}

@end
