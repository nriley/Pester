//
//  NJRSoundManager.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRSoundManager.h"
#import "NJRSoundDevice.h"

@implementation NJRSoundManager


+ (BOOL)volumeIsNotMutedOrInvalid:(float)volume;
{
    return (volume > 0 && volume <= 1);
}

{
}

+ (BOOL)getDefaultOutputVolume:(float *)volume;
{
    return [[NJRSoundDevice defaultOutputDevice] getOutputVolume: volume];
}

+ (BOOL)saveDefaultOutputVolume;
{
    return [[NJRSoundDevice defaultOutputDevice] saveOutputVolume];
}

+ (void)setDefaultOutputVolume:(float)volume;
{
    [[NJRSoundDevice defaultOutputDevice] setOutputVolume: volume];
}

+ (void)restoreSavedDefaultOutputVolume;
{
    [[NJRSoundDevice defaultOutputDevice] restoreSavedOutputVolume];
}

+ (void)restoreSavedDefaultOutputVolumeIfCurrently:(float)volume;
{
    [[NJRSoundDevice defaultOutputDevice] restoreSavedOutputVolumeIfCurrently: volume];
}

@end
