//
//  NJRQTMediaPopUpButton.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BDAlias.h"

extern NSString * const NJRQTMediaPopUpButtonMovieChangedNotification;

@interface NJRQTMediaPopUpButton : NSPopUpButton {
    IBOutlet NSMovieView *preview;
    BOOL movieCanRepeat;
    NSMenuItem *otherItem;
    BDAlias *selectedAlias, *previousAlias;
    NSMutableArray *recentMediaAliasData;
    BOOL dragAccepted;
}

- (BDAlias *)selectedAlias;
- (void)setAlias:(BDAlias *)alias;

- (BOOL)canRepeat;

- (IBAction)stopSoundPreview:(id)sender;

@end