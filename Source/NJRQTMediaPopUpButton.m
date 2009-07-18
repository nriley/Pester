//
//  NJRQTMediaPopUpButton.m
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "NJRQTMediaPopUpButton.h"
#import "NJRSoundManager.h"
#import "QTMovie-NJRExtensions.h"
#import "NSMenuItem-NJRExtensions.h"

#include <limits.h>

static const int NJRQTMediaPopUpButtonMaxRecentItems = 10;

NSString * const NJRQTMediaPopUpButtonMovieChangedNotification = @"NJRQTMediaPopUpButtonMovieChangedNotification";

@interface NJRQTMediaPopUpButton (Private)
- (void)_setPath:(NSString *)path;
- (NSMenuItem *)_itemForAlias:(BDAlias *)alias;
- (BOOL)_validateWithPreview:(BOOL)doPreview;
- (void)_startSoundPreview;
- (void)_resetPreview;
- (void)_resetOutputVolume;
@end

@implementation NJRQTMediaPopUpButton

// XXX handle refreshing sound list on resume
// XXX don't add icons on Puma, they look like ass
// XXX launch preview on a separate thread (if movies take too long to load, they inhibit the interface responsiveness)

// Recent media layout:
// Most recent media are at TOP of menu (smaller item numbers, starting at [self indexOfItem: otherItem] + 1)
// Most recent media are at END of array (larger indices)

#pragma mark recently selected media tracking

- (NSString *)_defaultKey;
{
    NSAssert([self tag] != 0, NSLocalizedString(@"Can't track recently selected media for popup with tag 0: please set a tag", "Assertion for QuickTime media popup button if tag is 0"));
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
    NSMenuItem *item;
    if (title == nil || path == nil) return nil;
    item = [menu insertItemWithTitle: title action: @selector(_aliasSelected:) keyEquivalent: @"" atIndex: [menu indexOfItem: otherItem] + 1];
    [item setTarget: self];
    [item setRepresentedObject: alias];
    [item setImageFromPath: path];
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
    NSEnumerator *e = [recentMediaAliasData reverseObjectEnumerator];
    NSData *aliasData;
    NSMenuItem *item;
    BDAlias *itemAlias;
    int otherIndex = [self indexOfItem: otherItem];
    int aliasDataCount = [recentMediaAliasData count];
    int lastItemIndex = [self numberOfItems] - 1;
    int recentItemCount = lastItemIndex - otherIndex;
    int recentItemIndex = otherIndex;
    NSAssert2(recentItemCount == aliasDataCount, @"Counted %d recent menu items, %d of alias data", recentItemCount, aliasDataCount);
    while ( (aliasData = [e nextObject]) != nil) { // go BACKWARD through array while going DOWN menu
        recentItemIndex++;
        item = [self itemAtIndex: recentItemIndex];
        itemAlias = [item representedObject];
    }
}

#pragma mark initialize-release

- (void)_setUp;
{
    NSMenu *menu = [self menu];
    [self removeAllItems];
    [menu setAutoenablesItems: NO];

    NSMenuItem *item = [menu addItemWithTitle: @"Alert sound" action: @selector(_beepSelected:) keyEquivalent: @""];
    [item setTarget: self];
    [menu addItem: [NSMenuItem separatorItem]];

    NSMutableArray *soundFolderPaths = [[NSMutableArray alloc] initWithCapacity: kLastDomainConstant - kSystemDomain + 1];
    for (FSVolumeRefNum domain = kSystemDomain ; domain <= kLastDomainConstant ; domain++) {
	OSStatus err;
	FSRef fsr;
	err = FSFindFolder(domain, kSystemSoundsFolderType, false, &fsr);
	if (err != noErr) continue;

	UInt8 path[PATH_MAX];
	err = FSRefMakePath(&fsr, path, PATH_MAX);
	if (err != noErr) continue;

	CFStringRef pathString = CFStringCreateWithFileSystemRepresentation(NULL, (const char *)path);
	if (pathString == NULL) continue;

	[soundFolderPaths addObject: (NSString *)pathString];
	CFRelease(pathString);
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSEnumerator *e = [soundFolderPaths objectEnumerator];
    NSString *folderPath;
    while ( (folderPath = [e nextObject]) != nil) {
	if (![fm changeCurrentDirectoryPath: folderPath]) continue;

	NSDirectoryEnumerator *de = [fm enumeratorAtPath: folderPath];
	NSString *path;
	while ( (path = [de nextObject]) != nil) {
	    BOOL isDir;
	    if (![fm fileExistsAtPath: path isDirectory: &isDir] || isDir) {
		[de skipDescendents];
		continue;
	    }

	    if (![QTMovie canInitWithFile: path]) continue;
	    
	    item = [menu addItemWithTitle: [fm displayNameAtPath: path]
				   action: @selector(_systemSoundSelected:)
			    keyEquivalent: @""];
            [item setTarget: self];
            [item setImageFromPath: path];
	    path = [folderPath stringByAppendingPathComponent: path];
            [item setRepresentedObject: path];
	    [item setToolTip: path];
        }
    }
    [soundFolderPaths release];
    
    if ([menu numberOfItems] == 2) {
        item = [menu addItemWithTitle: NSLocalizedString(@"Can't locate alert sounds", "QuickTime media popup menu item surrogate for alert sound list if no sounds are found") action: nil keyEquivalent: @""];
        [item setEnabled: NO];
    }
	 
    [menu addItem: [NSMenuItem separatorItem]];
    item = [menu addItemWithTitle: NSLocalizedString(@"Other...", "Media popup item to select another sound/movie/image") action: @selector(select:) keyEquivalent: @""];
    [item setTarget: self];
    otherItem = [item retain];

    [self _validateWithPreview: NO];

    recentMediaAliasData = [[NSMutableArray alloc] initWithCapacity: NJRQTMediaPopUpButtonMaxRecentItems + 1];
    [self _addRecentMediaFromAliasesData: [[NSUserDefaults standardUserDefaults] arrayForKey: [self _defaultKey]]];
    // [self _validateRecentMedia];

    [self registerForDraggedTypes:
        [NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType, nil]];
}

- (id)initWithFrame:(NSRect)frame;
{
    if ( (self = [super initWithFrame: frame]) != nil) {
        [self _setUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if ( (self = [super initWithCoder: coder]) != nil) {
        [self _setUp];
    }
    return self;
}

- (void)dealloc;
{
    [recentMediaAliasData release]; recentMediaAliasData = nil;
    [otherItem release];
    [selectedAlias release]; [previousAlias release];
    [super dealloc];
}

#pragma mark accessing

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

- (void)setAlias:(BDAlias *)alias;
{
    [self _setAlias: alias];
    if ([self _validateWithPreview: NO]) {
        [self selectItem: [self _itemForAlias: selectedAlias]];
    }
}

- (void)_setPath:(NSString *)path;
{
    [self _setAlias: [BDAlias aliasWithPath: path]];
}

- (NSMenuItem *)_itemForAlias:(BDAlias *)alias;
{
    if (alias == nil) return [self itemAtIndex: 0];

    // [self _validateRecentMedia];
    NSString *path = [alias fullPath];

    // selected a system sound?
    int itemIndex = [[self menu] indexOfItemWithRepresentedObject: path];
    if (itemIndex != -1) {
        // NSLog(@"_itemForAlias: selected system sound");
        return [self itemAtIndex: itemIndex];
    } else {
        NSEnumerator *e = [recentMediaAliasData reverseObjectEnumerator];
        NSData *aliasData;
        NSMenuItem *item;
        int recentIndex = 1;

        while ( (aliasData = [e nextObject]) != nil) {
            // selected a recently selected, non-system sound?
            if ([alias aliasDataIsEqual: aliasData]) {
                int otherIndex = [self indexOfItem: otherItem];
                int menuIndex = recentIndex + otherIndex;
                if (menuIndex == otherIndex + 1) return [self itemAtIndex: menuIndex]; // already at top
                // remove item, add (at top) later
                // NSLog(@"_itemForAlias removing item: idx %d + otherItemIdx %d + 1 = %d [%@]", recentIndex, otherIndex, menuIndex, [self itemAtIndex: menuIndex]);
                [self removeItemAtIndex: menuIndex];
                [recentMediaAliasData removeObjectAtIndex: [recentMediaAliasData count] - recentIndex];
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

- (BOOL)canRepeat;
{
    return movieCanRepeat;
}

- (BOOL)hasAudio;
{
    return movieHasAudio;
}

- (float)outputVolume;
{
    return outputVolume;
}

- (void)setOutputVolume:(float)volume withPreview:(BOOL)doPreview;
{
    if (![NJRSoundManager volumeIsNotMutedOrInvalid: volume]) return;
    outputVolume = volume;
    if (!doPreview) return;
    // NSLog(@"setting volume to %f, preview movie %@", volume, [preview movie]);
    if ([preview movie] == nil) {
        [self _validateWithPreview: YES];
    } else {
        [self _startSoundPreview];
    }
}

#pragma mark selected media validation

- (void)_invalidateSelection;
{
    [self _setAlias: previousAlias];
    [self selectItem: [self _itemForAlias: [self selectedAlias]]];
    [[NSNotificationCenter defaultCenter] postNotificationName: NJRQTMediaPopUpButtonMovieChangedNotification object: self];
}

- (void)_startSoundPreview;
{
    if ([preview movie] == nil || outputVolume == kNoVolume)
	return;

    if (savedVolume || [NJRSoundManager saveDefaultOutputVolume]) {
        savedVolume = YES;
        [NJRSoundManager setDefaultOutputVolume: outputVolume];
    }

    if ([[preview movie] rate] != 0)
	return; // don't restart preview if already playing
    
    [[NSNotificationCenter defaultCenter] addObserver: self
					     selector: @selector(_soundPreviewDidEnd:)
						 name: QTMovieDidEndNotification
					       object: [preview movie]];
    [preview play: self];
}

- (void)_soundPreviewDidEnd:(NSNotification *)notification;
{
    [self _resetPreview];
}

- (void)_resetPreview;
{
    [preview setMovie: nil];
    [self _resetOutputVolume];
}

- (void)_resetOutputVolume;
{
    [NJRSoundManager restoreSavedDefaultOutputVolumeIfCurrently: outputVolume];
    savedVolume = NO;
}

- (BOOL)_validateWithPreview:(BOOL)doPreview;
{
    // prevent _resetPreview from triggering afterward (crashes)
    [[NSNotificationCenter defaultCenter] removeObserver: self
						    name: QTMovieDidEndNotification
						  object: [preview movie]];
    [preview pause: self];
    if (selectedAlias == nil) {
        [preview setMovie: nil];
        movieCanRepeat = YES;
        movieHasAudio = NO; // XXX should be YES - this is broken, NSBeep() is asynchronous
        if (doPreview) {
            // XXX [self _updateOutputVolume];
            NSBeep();
            // XXX [self _resetOutputVolume];
        }
    } else {
	NSError *error;
	QTMovie *movie = [[QTMovie alloc] initWithFile: [selectedAlias fullPath] error: &error];
        movieCanRepeat = ![movie NJR_isStatic];
        if (movieHasAudio = [movie NJR_hasAudio]) {
            [preview setMovie: doPreview ? movie : nil];
        } else {
            [self _resetPreview];
            doPreview = NO;
            if (movie == nil) {
                NSBeginAlertSheet(@"Format not recognized", nil, nil, nil, [self window], nil, nil, nil, nil, [NSString stringWithFormat: NSLocalizedString(@"The item you selected isn't an image, sound or movie recognized by QuickTime. (%@)\n\nPlease select a different item.", "Message displayed in alert sheet when media document is not recognized by QuickTime"), [error localizedDescription]]);
                [self _invalidateSelection];
                return NO;
            }
            if (![movie NJR_hasAudio] && ![movie NJR_hasVideo]) {
                NSBeginAlertSheet(@"No video or audio", nil, nil, nil, [self window], nil, nil, nil, nil, NSLocalizedString(@"'%@' contains neither audio nor video content playable by QuickTime.\n\nPlease select a different item.", "Message displayed in alert sheet when media document is readable, but has neither audio nor video tracks"), [[NSFileManager defaultManager] displayNameAtPath: [selectedAlias fullPath]]);
                [self _invalidateSelection];
                [movie release];
                return NO;
            }
        }
        if (doPreview) {
            [self _startSoundPreview];
        }
        [movie release];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName: NJRQTMediaPopUpButtonMovieChangedNotification object: self];
    return YES;
}

#pragma mark actions

- (IBAction)stopSoundPreview:(id)sender;
{
    [preview pause: self];
    [self _resetPreview];
}

- (void)_beepSelected:(NSMenuItem *)sender;
{
    [self _setAlias: nil];
    [self _validateWithPreview: YES];
}

- (void)_systemSoundSelected:(NSMenuItem *)sender;
{
    [self _setPath: [sender representedObject]];
    if (![self _validateWithPreview: YES]) {
        [[self menu] removeItem: sender];
    }
}

- (void)_aliasSelected:(NSMenuItem *)sender;
{
    BDAlias *alias = [sender representedObject];
    int index = [self indexOfItem: sender], otherIndex = [self indexOfItem: otherItem];
    [self _setAlias: alias];
    if (![self _validateWithPreview: YES]) {
        [[self menu] removeItem: sender];
    } else if (index > otherIndex + 1) { // move "other" item to top of list
        int recentIndex = [recentMediaAliasData count] - index + otherIndex;
        NSMenuItem *item = [[self itemAtIndex: index] retain];
        NSData *data = [[recentMediaAliasData objectAtIndex: recentIndex] retain];
        // [self _validateRecentMedia];
        [self removeItemAtIndex: index];
        [[self menu] insertItem: item atIndex: otherIndex + 1];
        [self selectItem: item];
        [item release];
        NSAssert(recentIndex >= 0, @"Recent media index invalid");
        // NSLog(@"_aliasSelected removing item %d - %d + %d = %d of recentMediaAliasData", [recentMediaAliasData count], index, otherIndex, recentIndex);
        [recentMediaAliasData removeObjectAtIndex: recentIndex];
        [recentMediaAliasData addObject: data];
        [self _validateRecentMedia];
        [data release];
    } // else NSLog(@"_aliasSelected ...already at top");
}

- (IBAction)select:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString *path = [selectedAlias fullPath];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setCanChooseFiles: YES];
    [openPanel setDelegate: self];
    [openPanel beginSheetForDirectory: [path stringByDeletingLastPathComponent]
                                 file: [path lastPathComponent]
                                types: nil
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
        if ([self _validateWithPreview: YES]) {
            [self selectItem: [self _itemForAlias: selectedAlias]];
        }
    } else {
        // "Other..." item is still selected, revert to previously selected item
        // XXX issue with cancelling, top item in recent menu is sometimes duplicated!?
        [self selectItem: [self _itemForAlias: selectedAlias]];
    }
    // [self _validateRecentMedia];
}

- (void)setEnabled:(BOOL)flag;
{
    [super setEnabled: flag];
    if (flag) ; // XXX [self startSoundPreview: self]; // need to prohibit at startup
    else [self stopSoundPreview: self];
}

#pragma mark drag feedback

- (void)drawRect:(NSRect)rect;
{
    if (dragAccepted) {
        NSWindow *window = [self window];
        NSRect boundsRect = [self bounds];
        BOOL isFirstResponder = ([window firstResponder] == self);
        // focus ring and drag feedback interfere with one another
        if (isFirstResponder) [window makeFirstResponder: window];
        [super drawRect: rect];
        [[NSColor selectedControlColor] set];
        NSFrameRectWithWidthUsingOperation(NSInsetRect(boundsRect, 2, 2), 3, NSCompositeSourceIn);
        if (isFirstResponder) [window makeFirstResponder: self];
    } else {
        [super drawRect: rect];
    }
}

@end

@implementation NJRQTMediaPopUpButton (NSSavePanelDelegate)

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)filename;
{
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath: filename isDirectory: &isDir];

    if (isDir)
	return YES;

    return [QTMovie canInitWithFile: filename];
}

@end

@implementation NJRQTMediaPopUpButton (NSDraggingDestination)

- (BOOL)acceptsDragFrom:(id <NSDraggingInfo>)sender;
{
    NSURL *url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;

    if (url == nil || ![url isFileURL]) return NO;

    if (![fm fileExistsAtPath: [url path] isDirectory: &isDir]) return NO;

    if (isDir) return NO;
    
    return YES;
}

- (NSString *)_descriptionForDraggingInfo:(id <NSDraggingInfo>)sender;
{
    NSDragOperation mask = [sender draggingSourceOperationMask];
    NSMutableString *s = [NSMutableString stringWithFormat: @"Drag seq %d source: %@",
        [sender draggingSequenceNumber], [sender draggingSource]];
    NSPasteboard *draggingPasteboard = [sender draggingPasteboard];
    NSArray *types = [draggingPasteboard types];
    NSEnumerator *e = [types objectEnumerator];
    NSString *type;
    [s appendString: @"\nDrag operations:"];
    if (mask & NSDragOperationCopy) [s appendString: @" copy"];
    if (mask & NSDragOperationLink) [s appendString: @" link"];
    if (mask & NSDragOperationGeneric) [s appendString: @" generic"];
    if (mask & NSDragOperationPrivate) [s appendString: @" private"];
    if (mask & NSDragOperationMove) [s appendString: @" move"];
    if (mask & NSDragOperationDelete) [s appendString: @" delete"];
    if (mask & NSDragOperationEvery) [s appendString: @" every"];
    if (mask & NSDragOperationNone) [s appendString: @" none"];
    [s appendFormat: @"\nImage: %@ at %@", [sender draggedImage],
        NSStringFromPoint([sender draggedImageLocation])];
    [s appendFormat: @"\nDestination: %@ at %@", [sender draggingDestinationWindow],
        NSStringFromPoint([sender draggingLocation])];
    [s appendFormat: @"\nPasteboard: %@ types:", draggingPasteboard];
    while ( (type = [e nextObject]) != nil) {
        if ([type hasPrefix: @"CorePasteboardFlavorType 0x"]) {
            const char *osTypeHex = [[type substringFromIndex: [type rangeOfString: @"0x" options: NSBackwardsSearch].location] lossyCString];
            OSType osType;
            sscanf(osTypeHex, "%lx", &osType);
            [s appendFormat: @" '%4s'", &osType];
        } else {
            [s appendFormat: @" '%@'", type];
        }
    }
    return s;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
{
    if ([self acceptsDragFrom: sender] && [sender draggingSourceOperationMask] &
        (NSDragOperationCopy | NSDragOperationLink)) {
        dragAccepted = YES;
        [self setNeedsDisplay: YES];
        // NSLog(@"draggingEntered accept:\n%@", [self _descriptionForDraggingInfo: sender]);
        return NSDragOperationLink;
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
        if ([self _validateWithPreview: YES]) {
            [self selectItem: [self _itemForAlias: selectedAlias]];
        }
    }
    return YES;
}

@end
