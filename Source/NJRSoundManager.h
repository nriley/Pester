//
//  NJRSoundManager.h
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NJRSoundManager : NSObject {

}

+ (BOOL)shouldOverrideOutputVolume;

+ (BOOL)getDefaultOutputVolume:(float *)volume;
+ (void)setDefaultOutputVolume:(float)volume;
+ (BOOL)volumeIsNotMutedOrInvalid:(float)volume;

+ (BOOL)saveDefaultOutputVolume;
+ (void)restoreSavedDefaultOutputVolume;
+ (void)restoreSavedDefaultOutputVolumeIfCurrently:(float)volume;

@end