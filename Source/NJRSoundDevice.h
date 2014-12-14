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

extern NSString * const NJRSoundDeviceListChangedNotification;
extern NSString * const NJRSoundDeviceDefaultOutputDeviceChangedNotification;

@interface NJRSoundDevice : NSObject {
    NSString *name;
    NSString *uid;
    AudioDeviceID deviceID;
    BOOL registeredSourceListener;
}

+ (NSArray *)allOutputDevices;
+ (NJRSoundDevice *)defaultOutputDevice;
+ (NJRSoundDevice *)setDefaultOutputDeviceByUID:(NSString *)uid;

- (NSString *)name;
- (NSString *)uid;

#if !__LP64__
- (QTAudioContextRef)quickTimeAudioContext;
#endif
- (AudioDeviceID)deviceID;

+ (BOOL)volumeIsNotMutedOrInvalid:(float)volume;

@end
