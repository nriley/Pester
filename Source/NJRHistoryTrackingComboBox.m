//
//  NJRHistoryTrackingComboBox.m
//  DockCam
//
//  Created by Nicholas Riley on Fri Jun 28 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRHistoryTrackingComboBox.h"

#define NJRHistoryTrackingComboBoxMaxItems 100

@interface NJRHistoryTrackingComboBox ()
- (void)clearAllSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)optionKeyStateChanged:(BOOL)down;
@end

@implementation NJRHistoryTrackingComboBox

- (NSString *)_defaultKey;
{
    NSAssert([self tag] != 0, NSLocalizedString(@"Can't track history for combo box with tag 0: please set a tag", "Assertion for history tracking combo box if tag is 0"));
    return [NSString stringWithFormat: @"NJRHistoryTrackingComboBox tag %ld", (long)[self tag]];
}

- (void)awakeFromNib;
{
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(textDidEndEditing:)
                                                 name: NSTextDidEndEditingNotification
                                               object: self];
    [self removeAllItems];
    [self addItemsWithObjectValues: [[NSUserDefaults standardUserDefaults] stringArrayForKey: [self _defaultKey]]];

    if (removeEntryButton == nil)
	return;

    flagsChangedEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask: NSFlagsChangedMask handler: ^NSEvent *(NSEvent *event) {
        [self optionKeyStateChanged: (event.modifierFlags & NSAlternateKeyMask) != 0];
        return event;
    }];
}

- (void)dealloc;
{
    [NSEvent removeMonitor: flagsChangedEventMonitor];
    [super dealloc];
}

- (void)_writeHistory;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [self objectValues] forKey: [self _defaultKey]];
    [defaults synchronize];
}

- (void)_clearEntry;
{
    [self setStringValue: @""];
    // force bindings to update
    [self textDidChange: [NSNotification notificationWithName: NSControlTextDidChangeNotification
						       object: [[self window] fieldEditor: NO forObject: self]]];
}

- (IBAction)removeEntry:(id)sender;
{
    if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
	NSBeginAlertSheet(@"Are you sure you want to remove all recent messages from the list?", @"Remove All", @"Cancel", nil, [self window], self, @selector(clearAllSheetDidEnd:returnCode:contextInfo:), NULL, NULL, @"You can't undo this action.");
	return;
    }

    int idx = [self indexOfSelectedItem];
    if (idx == -1) {
        [self selectItemWithObjectValue: [self stringValue]];
        idx = [self indexOfSelectedItem];
    }
    if (idx != -1) [self removeItemAtIndex: idx];
    [self _clearEntry];
    [self _writeHistory];
}

- (void)clearAllSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode != NSAlertDefaultReturn)
	return;

    [self clearAllEntries: nil];
}

- (IBAction)clearAllEntries:(id)sender;
{
    [self removeAllItems];
    [self setStringValue: @""];
    [self _clearEntry];
    [self _writeHistory];
}

- (void)optionKeyStateChanged:(BOOL)down;
{
    if (!down && removeEntryButtonEnabledBindingInfo != nil) {
	[removeEntryButton setEnabled: NO];
	[removeEntryButton bind: NSEnabledBinding
		       toObject: [removeEntryButtonEnabledBindingInfo objectForKey: NSObservedObjectKey]
		    withKeyPath: [removeEntryButtonEnabledBindingInfo objectForKey: NSObservedKeyPathKey]
			options: [removeEntryButtonEnabledBindingInfo objectForKey: NSOptionsKey]];
	[removeEntryButtonEnabledBindingInfo release];
	removeEntryButtonEnabledBindingInfo = nil;
    }

    if (down) {
	removeEntryButtonEnabledBindingInfo = [[removeEntryButton infoForBinding: NSEnabledBinding] retain];
	[removeEntryButton unbind: NSEnabledBinding];
	[removeEntryButton setEnabled: YES];
    }
}

- (BOOL)textShouldEndEditing:(NSText *)textObject;
{
    NSString *newValue = [self stringValue];
    int oldIndex = [self indexOfItemWithObjectValue: newValue];
    if ([newValue length] == 0) return YES; // don't save empty entries
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
