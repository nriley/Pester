//
//  NJRQTMediaPopUpButton.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <QTKit/QTKit.h>
#import "BDAlias.h"

extern NSString * const NJRQTMediaPopUpButtonMovieChangedNotification;

@interface NJRQTMediaPopUpButton : NSPopUpButton <NSOpenSavePanelDelegate> {
    IBOutlet QTMovieView *preview;
    BOOL mediaCanRepeat, mediaCanAdjustVolume;
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

- (IBAction)stopSoundPreview:(id)sender;

@end