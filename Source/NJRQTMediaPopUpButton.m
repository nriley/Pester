//
//  NJRQTMediaPopUpButton.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRQTMediaPopUpButton.h"
#import "SoundFileManager.h"
#import "NSMovie-NJRExtensions.h"
#import "NSImage-NJRExtensions.h"

static const int NJRQTMediaPopUpButtonMaxRecentItems = 10;

@interface NJRQTMediaPopUpButton (Private)
- (void)_setPath:(NSString *)path;
- (BOOL)_validatePreview;
@end

@implementation NJRQTMediaPopUpButton

// XXX handle refreshing sound list on resume
// XXX don't add icons on Puma, they look like ass
// XXX launch preview on a separate thread (if movies take too long to load, they inhibit the interface responsiveness)

- (NSString *)_defaultKey;
{
    NSAssert([self tag] != 0, @"Can’t track recently selected media for popup with tag 0: please set a tag");
    return [NSString stringWithFormat: @"NJRQTMediaPopUpButtonMaxRecentItems tag %d", [self tag]];
}

- (void)_writeRecentMedia;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: recentMediaAliasData forKey: [self _defaultKey]];
    [defaults synchronize];
}

- (NSMenuItem *)_addRecentMediaAtPath:(NSString *)path withAlias:(BDAlias *)alias;
{
    NSString *title = [[NSFileManager defaultManager] displayNameAtPath: path];
    NSMenu *menu = [self menu];
    NSMenuItem *item = [menu insertItemWithTitle: title action: @selector(_aliasSelected:) keyEquivalent: @"" atIndex: [menu indexOfItem: otherItem] + 1];
    [item setTarget: self];
    [item setRepresentedObject: alias];
    [item setImage: [[[NSWorkspace sharedWorkspace] iconForFile: path] bestFitImageForSize: NSMakeSize(16, 16)]];
    [recentMediaAliasData addObject: [alias aliasData]];
    if ([recentMediaAliasData count] > NJRQTMediaPopUpButtonMaxRecentItems) {
        [menu removeItemAtIndex: [menu numberOfItems] - 1];
        [recentMediaAliasData removeObjectAtIndex: 0];
    }
    return item;
}

- (void)_addRecentMediaFromAliasesData:(NSArray *)aliasesData;
{
    NSEnumerator *e = [aliasesData objectEnumerator];
    NSData *aliasData;
    BDAlias *alias;
    while ( (aliasData = [e nextObject]) != nil) {
        if ( (alias = [[BDAlias alloc] initWithData: aliasData]) != nil) {
            [self _addRecentMediaAtPath: [alias fullPath] withAlias: alias];
            [alias release];
        }
    }
}

- (void)_validateRecentMedia;
{
    NSEnumerator *e = [recentMediaAliasData objectEnumerator];
    NSData *aliasData;
    NSMenuItem *item;
    BDAlias *itemAlias;
    int otherIndex = [self indexOfItem: otherItem];
    int aliasDataCount = [recentMediaAliasData count];
    int lastItemIndex = [self numberOfItems] - 1;
    int recentItemCount = lastItemIndex - otherIndex;
    int recentItemIndex = otherIndex;
    NSAssert2(recentItemCount == aliasDataCount, @"Counted %d recent menu items, %d of alias data", recentItemCount, aliasDataCount);
    while ( (aliasData = [e nextObject]) != nil) {
        recentItemIndex++;
        item = [self itemAtIndex: recentItemIndex];
        itemAlias = [item representedObject];
        if (![itemAlias aliasDataIsEqual: aliasData])
            NSLog(@"item %d %@: %@", recentItemIndex, [item title], [itemAlias fullPath]);
        else
            NSLog(@"ITEM %d %@: %@ != aliasData %@", recentItemIndex, [item title], [itemAlias fullPath], [[BDAlias aliasWithData: aliasData] fullPath]);
    }
}

- (void)awakeFromNib;
{
    NSMenu *menu;
    NSMenuItem *item;
    SoundFileManager *sfm = [SoundFileManager sharedSoundFileManager];
    int soundCount = [sfm count];

    [self removeAllItems];
    menu = [self menu];
    item = [menu addItemWithTitle: @"Alert sound" action: @selector(_beepSelected:) keyEquivalent: @""];
    [item setTarget: self];
    [menu addItem: [NSMenuItem separatorItem]];
    if (soundCount == 0) {
        item = [menu addItemWithTitle: @"Can’t locate alert sounds" action: nil keyEquivalent: @""];
        [item setEnabled: NO];
    } else {
        SoundFile *sf;
        int i;
        [sfm sortByName];
        for (i = 0 ; i < soundCount ; i++) {
            sf = [sfm soundFileAtIndex: i];
            item = [menu addItemWithTitle: [sf name] action: @selector(_soundFileSelected:) keyEquivalent: @""];
            [item setTarget: self];
            [item setRepresentedObject: sf];
            [item setImage: [[[NSWorkspace sharedWorkspace] iconForFile: [sf path]] bestFitImageForSize: NSMakeSize(16, 16)]];
        }
    }
    [menu addItem: [NSMenuItem separatorItem]];
    item = [menu addItemWithTitle: @"Other…" action: @selector(select:) keyEquivalent: @""];
    [item setTarget: self];
    otherItem = [item retain];

    recentMediaAliasData = [[NSMutableArray alloc] initWithCapacity: NJRQTMediaPopUpButtonMaxRecentItems + 1];
    [self _addRecentMediaFromAliasesData: [[NSUserDefaults standardUserDefaults] arrayForKey: [self _defaultKey]]];

    [self registerForDraggedTypes:
        [NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType, nil]];
}

- (void)dealloc;
{
    [recentMediaAliasData release]; recentMediaAliasData = nil;
    [otherItem release];
    [selectedAlias release]; [previousAlias release];
    [super dealloc];
}

- (BDAlias *)selectedAlias;
{
    return selectedAlias;
}

- (void)_setAlias:(BDAlias *)alias;
{
    
    BDAlias *oldAlias = [selectedAlias retain];
    [previousAlias release];
    previousAlias = oldAlias;
    if (selectedAlias != alias) {
        [selectedAlias release];
        selectedAlias = [alias retain];
    }
}

- (void)_setPath:(NSString *)path;
{
    [self _setAlias: [BDAlias aliasWithPath: path]];
}

- (NSMenuItem *)_itemForAlias:(BDAlias *)alias;
{
    NSString *path;
    SoundFile *sf;
    if (alias == nil) {
        return [self itemAtIndex: 0];
    }

    // [self _validateRecentMedia];
    path = [alias fullPath];
    sf = [[SoundFileManager sharedSoundFileManager] soundFileFromPath: path];
    NSLog(@"_itemForAlias: %@", path);

    // selected a system sound?
    if (sf != nil) {
        NSLog(@"_itemForAlias: selected system sound");
        return [self itemAtIndex: [self indexOfItemWithRepresentedObject: sf]];
    } else {
        NSEnumerator *e = [recentMediaAliasData objectEnumerator];
        NSData *aliasData;
        NSMenuItem *item;
        int recentIndex = 0;

        while ( (aliasData = [e nextObject]) != nil) {
            // selected a recently selected, non-system sound?
            if ([alias aliasDataIsEqual: aliasData]) {
                int otherIndex = [self indexOfItem: otherItem];
                int menuIndex = [recentMediaAliasData count] - recentIndex + otherIndex + 1;
                if (menuIndex == otherIndex + 1) return [self itemAtIndex: menuIndex]; // already at top
                // remove item, add (at top) later
                NSLog(@"_itemForAlias removing item: count %d - idx %d + otherItemIndex %d + 1 = %d [%@]", [recentMediaAliasData count], recentIndex, otherIndex, menuIndex, [self itemAtIndex: menuIndex]);
                [self removeItemAtIndex: menuIndex];
                [recentMediaAliasData removeObjectAtIndex: recentIndex];
                break;
            }
            recentIndex++;
        }

        // create the item
        item = [self _addRecentMediaAtPath: path withAlias: alias];
        [self _writeRecentMedia];
        return item;
    }
}

- (void)_invalidateSelection;
{
    [self _setAlias: previousAlias];
    [self selectItem: [self _itemForAlias: [self selectedAlias]]];
}

- (BOOL)_validatePreview;
{
    [preview stop: self];
    if (selectedAlias == nil) {
        [preview setMovie: nil];
        NSBeep();
    } else {
        NSMovie *movie = [[NSMovie alloc] initWithURL: [NSURL fileURLWithPath: [selectedAlias fullPath]] byReference: YES];
        if ([movie hasAudio])
            [preview setMovie: movie];
        else {
            [preview setMovie: nil];
            if (movie == nil) {
                NSBeginAlertSheet(@"Format not recognized", @"OK", nil, nil, [self window], nil, nil, nil, nil, @"The item you selected isn’t a sound or movie recognized by QuickTime.  Please select a different item.");
                [self _invalidateSelection];
                return NO;
            }
            if (![movie hasAudio] && ![movie hasVideo]) {
                NSBeginAlertSheet(@"No video or audio", @"OK", nil, nil, [self window], nil, nil, nil, nil, @"“%@” contains neither audio nor video content playable by QuickTime.  Please select a different item.", [[NSFileManager defaultManager] displayNameAtPath: [selectedAlias fullPath]]);
                [self _invalidateSelection];
                [movie release];
                return NO;
            }
        }
        [movie release];
        [preview start: self];
    }
    return YES;
}

- (IBAction)stopSoundPreview:(id)sender;
{
    [preview stop: self];
}

- (void)_beepSelected:(NSMenuItem *)sender;
{
    [self _setAlias: nil];
    [self _validatePreview];
}

- (void)_soundFileSelected:(NSMenuItem *)sender;
{
    [self _setPath: [(SoundFile *)[sender representedObject] path]];
    if (![self _validatePreview]) {
        [[self menu] removeItem: sender];
    }
}

- (void)_aliasSelected:(NSMenuItem *)sender;
{
    BDAlias *alias = [sender representedObject];
    int index = [self indexOfItem: sender], otherIndex = [self indexOfItem: otherItem];
    [self _setAlias: alias];
    if (![self _validatePreview]) {
        [[self menu] removeItem: sender];
    } else if (index > otherIndex + 1) { // move "other" item to top of list
        int recentIndex = [recentMediaAliasData count] - index + otherIndex + 1;
        NSMenuItem *item = [[self itemAtIndex: index] retain];
        NSData *data = [[recentMediaAliasData objectAtIndex: recentIndex] retain];
        [self removeItemAtIndex: index];
        [[self menu] insertItem: item atIndex: otherIndex + 1];
        [self selectItem: item];
        [item release];
        NSAssert(recentIndex >= 0, @"Recent media index invalid");
        NSLog(@"_aliasSelected removing item %d - %d + %d + 1 = %d of recentMediaAliasData", [recentMediaAliasData count], index, otherIndex, recentIndex);
        [recentMediaAliasData removeObjectAtIndex: recentIndex];
        [recentMediaAliasData addObject: data];
        [data release];
    } else NSLog(@"_aliasSelected ...already at top");
}

- (IBAction)select:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString *path = [selectedAlias fullPath];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setCanChooseFiles: YES];
    [openPanel beginSheetForDirectory: [path stringByDeletingLastPathComponent]
                                 file: [path lastPathComponent]
                                types: nil // XXX fix for QuickTime!
                       modalForWindow: [self window]
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo: nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [sheet close];

    if (returnCode == NSOKButton) {
        NSArray *files = [sheet filenames];
        NSAssert1([files count] == 1, @"%d items returned, only one expected", [files count]);
        [self _setPath: [files objectAtIndex: 0]];
        if ([self _validatePreview]) {
            [self selectItem: [self _itemForAlias: selectedAlias]];
        }
    } else {
        // "Other..." item is still selected, revert to previously selected item
        // XXX issue with cancelling, top item in recent menu is sometimes duplicated!?
        [self selectItem: [self _itemForAlias: selectedAlias]];
    }
    // [self _validateRecentMedia];
}

@end

@implementation NJRQTMediaPopUpButton (NSDraggingDestination)

- (BOOL)acceptsDragFrom:(id <NSDraggingInfo>)sender;
{
    NSURL *url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];

    if (url == nil || ![url isFileURL]) return NO;
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
{
    if ([self acceptsDragFrom: sender] && [sender draggingSourceOperationMask] &
        NSDragOperationCopy) {
        dragAccepted = YES;
        [self setNeedsDisplay: YES];
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
    dragAccepted = NO;
    [self setNeedsDisplay: YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
    dragAccepted = NO;
    [self setNeedsDisplay: YES];
    return [self acceptsDragFrom: sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
{
    if ([sender draggingSource] != self) {
        NSURL *url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];
        if (url == nil) return NO;
        [self _setPath: [url path]];
        [self _validatePreview];
    }
    return YES;
}

@end
