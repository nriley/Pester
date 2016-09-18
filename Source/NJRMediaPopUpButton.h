//
//  NJRMediaPopUpButton.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class AVPlayer;
@class BDAlias;

extern NSString * const NJRMediaPopUpButtonMovieChangedNotification;

@interface NJRMediaPopUpButton : NSPopUpButton <NSOpenSavePanelDelegate> {
    AVPlayer *preview;
    BOOL mediaCanRepeat, mediaCanAdjustVolume, mediaHasVideo;
    NSMenuItem *otherItem;
    BDAlias *selectedAlias, *previousAlias;
    NSMutableArray *recentMediaAliasData;
    BOOL dragAccepted;
    float outputVolume;
}

- (BDAlias *)selectedAlias;
- (void)setAlias:(BDAlias *)alias;
- (float)outputVolume;
- (void)setOutputVolume:(float)volume withPreview:(BOOL)doPreview;

- (BOOL)canRepeat;
- (BOOL)canAdjustVolume;
- (BOOL)hasVideo;

- (IBAction)stopSoundPreview:(id)sender;

@end
