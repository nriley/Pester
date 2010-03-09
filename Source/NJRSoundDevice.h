//
//  NJRSoundDevice.h
//  Pester
//
//  Created by Nicholas Riley on 3/8/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>


@interface NJRSoundDevice : NSObject {
    NSString *name;
    AudioDeviceID deviceID;
    UInt32 stereoChannels[2];
    float channelVolume[2];
    float savedChannelVolume[2];
    BOOL canSetVolume;
}

+ (NSArray *)allOutputDevices;
+ (NJRSoundDevice *)defaultOutputDevice;

- (NSString *)name;
- (BOOL)canSetVolume;

- (BOOL)getOutputVolume:(float *)volume;
- (void)setOutputVolume:(float)volume;

- (BOOL)saveOutputVolume;
- (void)restoreSavedOutputVolume;
- (void)restoreSavedOutputVolumeIfCurrently:(float)volume;

@end
