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

@interface NJRQTMediaPopUpButton (Private)
- (BOOL)_previewSound;
@end

@implementation NJRQTMediaPopUpButton

// XXX handle refreshing sound list on resume
// XXX don't add icons on Puma
// XXX add saving of recently selected media
// XXX launch preview on a separate thread (if movies take too long to load, they inhibit the interface)

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

- (void)setAlias:(BDAlias *)alias;
{
    if (selectedAlias != alias) {
        [selectedAlias release];
        selectedAlias = [alias retain];
    }
}

- (void)setPath:(NSString *)path;
{
    [self setAlias: [BDAlias aliasWithPath: path]];
}

- (BDAlias *)selectedAlias;
{
    return selectedAlias;
}


- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [sheet close];

    if (returnCode == NSOKButton) {
        NSArray *files = [sheet filenames];
        NSAssert1([files count] == 1, @"%d items returned, only one expected", [files count]);
        [self setPath: [files objectAtIndex: 0]];
        if ([self _previewSound]) {
            NSString *path = [selectedAlias fullPath];
            SoundFile *sf = [[SoundFileManager sharedSoundFileManager] soundFileFromPath: path];
            if (sf != nil) {
                [self selectItemAtIndex: [self indexOfItemWithRepresentedObject: sf]];
            } else {
                NSString *title = [[NSFileManager defaultManager] displayNameAtPath: path];
                NSMenuItem *item = [[self menu] addItemWithTitle: title action: @selector(_aliasSelected:) keyEquivalent: @""];
                [item setTarget: self];
                [item setRepresentedObject: selectedAlias];
                [item setImage: [[[NSWorkspace sharedWorkspace] iconForFile: path] bestFitImageForSize: NSMakeSize(16, 16)]];
                [self selectItem: item];
            }
        }
    }
}

- (void)_beepSelected:(NSMenuItem *)sender;
{
    [self setAlias: nil];
    [self _previewSound];
}

- (void)_soundFileSelected:(NSMenuItem *)sender;
{
    [self setPath: [(SoundFile *)[sender representedObject] path]];
    [self _previewSound];
}

- (void)_aliasSelected:(NSMenuItem *)sender;
{
    [self setAlias: [sender representedObject]];
    [self _previewSound];
}

- (void)_invalidateSoundSelection;
{
    [self setAlias: nil];
    [self selectItemAtIndex: 0];
}

- (IBAction)stopSoundPreview:(id)sender;
{
    [preview stop: self];
}

- (BOOL)_previewSound;
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
                [self _invalidateSoundSelection];
                return NO;
            }
            if (![movie hasAudio] && ![movie hasVideo]) {
                NSBeginAlertSheet(@"No video or audio", @"OK", nil, nil, [self window], nil, nil, nil, nil, @"“%@” contains neither audio nor video content playable by QuickTime.  Please select a different item.", [[NSFileManager defaultManager] displayNameAtPath: [selectedAlias fullPath]]);
                [self _invalidateSoundSelection];
                [movie release];
                return NO;
            }
        }
        [movie release];
        [preview start: self];
    }
    return YES;
}

@end
