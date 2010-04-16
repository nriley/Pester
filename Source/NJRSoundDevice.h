//
//  NJRSoundDevice.h
//  Pester
//
//  Created by Nicholas Riley on 3/8/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import <QuickTime/QuickTime.h>


@interface NJRSoundDevice : NSObject {
    NSString *name;
    NSString *uid;
    AudioDeviceID deviceID;
    UInt32 stereoChannels[2];
    float channelVolume[2];
    float savedChannelVolume[2];
    BOOL canSetVolume;
}

+ (NSArray *)allOutputDevices;
+ (NJRSoundDevice *)defaultOutputDevice;
+ (NJRSoundDevice *)setDefaultOutputDeviceByUID:(NSString *)uid;

- (NSString *)name;
- (NSString *)uid;
- (BOOL)canSetVolume;

- (BOOL)getOutputVolume:(float *)volume;
- (void)setOutputVolume:(float)volume;

- (BOOL)saveOutputVolume;
- (void)restoreSavedOutputVolume;
- (void)restoreSavedOutputVolumeIfCurrently:(float)volume;

- (QTAudioContextRef)quickTimeAudioContext;
- (AudioDeviceID)deviceID;

@end
