//
//  PSVolumeController.h
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface PSVolumeController : NSWindowController {
    id delegate;
    IBOutlet NSView *contentView;
    IBOutlet NSSlider *volumeSlider;
    NSMenu *menu;
}

+ (PSVolumeController *)controllerWithVolume:(float)volume delegate:(id)aDelegate;

- (id)initWithVolume:(float)volume delegate:(id)aDelegate;

- (IBAction)volumeSet:(NSSlider *)sender;

@end

@interface NSObject (PSVolumeControllerDelegate)

- (void)volumeController:(PSVolumeController *)controller didSetVolume:(float)volume;
- (void)volumeControllerDidDismiss:(PSVolumeController *)controller;
- (NSView *)volumeControllerLaunchingView:(PSVolumeController *)controller;

@end