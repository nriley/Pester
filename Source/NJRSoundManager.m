//
//  NJRSoundManager.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRSoundManager.h"
#import "NJRSoundDevice.h"
#import <CoreAudio/CoreAudio.h>

@implementation NJRSoundManager

NJRSoundDevice *defaultOutputDevice;

+ (BOOL)volumeIsNotMutedOrInvalid:(float)volume;
{
    return (volume > 0 && volume <= 1);
}

+ (BOOL)_getDefaultOutputDevice;
{
    defaultOutputDevice = [NJRSoundDevice defaultOutputDevice];
    
    return (defaultOutputDevice != nil);
}

+ (BOOL)getDefaultOutputVolume:(float *)volume;
{
    if (![self _getDefaultOutputDevice]) return NO;
    
    return [defaultOutputDevice getOutputVolume: volume];
}

+ (BOOL)saveDefaultOutputVolume;
{
    if (![self getDefaultOutputVolume: NULL]) return NO;
    
    return [defaultOutputDevice saveOutputVolume];
}

+ (void)setDefaultOutputVolume:(float)volume;
{
    if (![self _getDefaultOutputDevice]) return;

    [defaultOutputDevice setOutputVolume: volume];
}

+ (void)restoreSavedDefaultOutputVolume;
{
    [defaultOutputDevice restoreSavedOutputVolume];
}

+ (void)restoreSavedDefaultOutputVolumeIfCurrently:(float)volume;
{
    [defaultOutputDevice restoreSavedOutputVolumeIfCurrently: volume];
}

@end
