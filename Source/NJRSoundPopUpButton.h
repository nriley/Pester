//
//  NJRSoundPopUpButton.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "BDAlias.h"

@interface NJRSoundPopUpButton : NSPopUpButton {
    IBOutlet NSMovieView *preview;
    BDAlias *selectedAlias;
}

- (BDAlias *)selectedAlias;
- (IBAction)stopSoundPreview:(id)sender;

@end
