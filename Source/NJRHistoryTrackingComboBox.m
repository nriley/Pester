//
//  NJRHistoryTrackingComboBox.m
//  DockCam
//
//  Created by Nicholas Riley on Fri Jun 28 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRHistoryTrackingComboBox.h"

#define NJRHistoryTrackingComboBoxMaxItems 10

@implementation NJRHistoryTrackingComboBox

- (NSString *)_defaultKey;
{
    NSAssert([self tag] != 0, @"CanÕt track history for combo box with tag 0: please set a tag");
    return [NSString stringWithFormat: @"NJRHistoryTrackingComboBox tag %d", [self tag]];
}

- (void)awakeFromNib;
{
    NSAssert([self tag] != 0, @"CanÕt track history for combo box with tag 0: please set a tag");
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(textDidEndEditing:)
                                                 name: NSTextDidEndEditingNotification
                                               object: self];
    [self removeAllItems];
    [self addItemsWithObjectValues: [[NSUserDefaults standardUserDefaults] stringArrayForKey: [self _defaultKey]]];
    [self setItemHeight: [self itemHeight] + 2];
}

- (void)_writeHistory;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [self objectValues] forKey: [self _defaultKey]];
    [defaults synchronize];
}

- (IBAction)removeEntry:(id)sender;
{
    int idx = [self indexOfSelectedItem];
    if (idx == -1) {
        [self selectItemWithObjectValue: [self stringValue]];
        idx = [self indexOfSelectedItem];
    }
    if (idx != -1) [self removeItemAtIndex: idx];
    [self setStringValue: @""];
    [self _writeHistory];
}

- (IBAction)clearAllEntries:(id)sender;
{
    [self removeAllItems];
    [self setStringValue: @""];
    [self _writeHistory];
}

- (BOOL)textShouldEndEditing:(NSText *)textObject;
{
    NSString *newValue = [self stringValue];
    int oldIndex = [self indexOfItemWithObjectValue: newValue];
    [self removeItemWithObjectValue: newValue];
    [self insertItemWithObjectValue: newValue atIndex: 0];
    if (oldIndex == NSNotFound) {
        int numItems = [self numberOfItems];
        while (numItems-- > NJRHistoryTrackingComboBoxMaxItems) {
            [self removeItemAtIndex: numItems - 1];
        }
    }
    [self _writeHistory];
    return YES;
}

@end