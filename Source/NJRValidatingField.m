//
//  NJRValidatingField.m
//  Pester
//
//  Created by Nicholas Riley on 11/27/07.
//  Copyright 2007 Nicholas Riley. All rights reserved.
//

#import "NJRValidatingField.h"


@implementation NJRValidatingField

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

- (void)handleDidFailToFormatString:(NSString *)string errorDescription:(NSString *)error label:(NSString *)label;
{
    NSString *alertMessage = nil;
    NSString *alternateButtonString = nil;
    NSNumber *proposedValue = nil;
    NSDictionary *contextInfo = nil;

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
            NSLocalizedString(@"%@ is too small for the %@ field.",
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
            NSLocalizedString(@"%@ is too large for the %@ field.",
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
            NSLocalizedString(@"%@ is not a valid entry for the %@ field.",
                              @"Message text for alert posed by text field when invalid value entered"),
            string, label];
    } else if (string == nil) {
	alertMessage = [NSString stringWithFormat:
	    NSLocalizedString(@"You must type a number in the %@ field.",
			      @"Message text for alert posed by text field when no value entered"),
	    label];
    }

    if (proposedValue != nil) {
	contextInfo = [NSDictionary dictionaryWithObject: proposedValue forKey: @"proposedValue"];
	[contextInfo retain];
    }
    NSBeep();
    NSBeginAlertSheet(alertMessage, defaultButtonString, alternateButtonString, otherButtonString, [self window],
                      self, @selector(validationFailedSheetDidEnd:returnCode:contextInfo:), NULL, contextInfo,
                      alertInformation);
}
@end
