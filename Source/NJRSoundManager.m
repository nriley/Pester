//
//  NJRSoundManager.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRSoundManager.h"
#import <CoreAudio/CoreAudio.h>

@implementation NJRSoundManager

static const UInt32 kLeftChannel = 0, kRightChannel = 1;

static AudioDeviceID deviceID;
static UInt32 stereoChannels[2];
static float channelVolume[2];
static float savedChannelVolume[2] = {-1, -1};

+ (BOOL)volumeIsNotMutedOrInvalid:(float)volume;
{
    return (volume > 0 && volume <= 1);
}

+ (BOOL)_getDefaultOutputDevice;
{
    UInt32 propertySize;
    OSStatus err;

    propertySize = sizeof(deviceID);
    err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultSystemOutputDevice, &propertySize, &deviceID);
    if (err != noErr) return NO;

    propertySize = sizeof(stereoChannels);
    err = AudioDeviceGetProperty(deviceID, 0, false, kAudioDevicePropertyPreferredChannelsForStereo, &propertySize, &stereoChannels);
    if (err != noErr) return NO;
    return YES;
}

+ (BOOL)getDefaultOutputVolume:(float *)volume;
{
    UInt32 propertySize;
    OSStatus err;

    if (![self _getDefaultOutputDevice]) return NO;
    
    // read the current volume scalar settings [0...1]
    propertySize = sizeof(float);
    err = AudioDeviceGetProperty(deviceID, stereoChannels[kLeftChannel], false, kAudioDevicePropertyVolumeScalar, &propertySize, &channelVolume[kLeftChannel]);
    if (err != noErr) return NO;
    err = AudioDeviceGetProperty(deviceID, stereoChannels[kRightChannel], false, kAudioDevicePropertyVolumeScalar, &propertySize, &channelVolume[kRightChannel]);
    if (err != noErr) return NO;
    if (volume != NULL) *volume = MAX(channelVolume[kLeftChannel], channelVolume[kRightChannel]);
    return YES;
}

+ (void)_updateChannelVolume;
{
    UInt32 propertySize = sizeof(channelVolume[kLeftChannel]);
    // ignore errors
    AudioDeviceSetProperty(deviceID, NULL, stereoChannels[kLeftChannel], false, kAudioDevicePropertyVolumeScalar, propertySize, &channelVolume[kLeftChannel]);
    AudioDeviceSetProperty(deviceID, NULL, stereoChannels[kRightChannel], false, kAudioDevicePropertyVolumeScalar, propertySize, &channelVolume[kRightChannel]);
}

+ (BOOL)saveDefaultOutputVolume;
{
    if (![self getDefaultOutputVolume: NULL]) return NO;
    savedChannelVolume[kLeftChannel] = channelVolume[kLeftChannel];
    savedChannelVolume[kRightChannel] = channelVolume[kRightChannel];
    // NSLog(@"saving channel volume {%f, %f}", channelVolume[kLeftChannel],channelVolume[kRightChannel]);
    return YES;
}

+ (void)setDefaultOutputVolume:(float)volume;
{
    if (![self _getDefaultOutputDevice]) return;

    channelVolume[kLeftChannel] = volume;
    channelVolume[kRightChannel] = volume;
    [self _updateChannelVolume];
}

+ (void)restoreSavedDefaultOutputVolume;
{
    if (savedChannelVolume[kLeftChannel] < 0) return;
    // NSLog(@"restoring saved channel volume");
    channelVolume[kLeftChannel] = savedChannelVolume[kLeftChannel];
    channelVolume[kRightChannel] = savedChannelVolume[kRightChannel];
    savedChannelVolume[kLeftChannel] = -1;
    savedChannelVolume[kRightChannel] = -1;
    [self _updateChannelVolume];
}

+ (void)restoreSavedDefaultOutputVolumeIfCurrently:(float)volume;
{
    float currentVolume;
    if ([self getDefaultOutputVolume: &currentVolume] && abs(volume - currentVolume) < 0.05) {
        [self restoreSavedDefaultOutputVolume];
    }
}

@end
