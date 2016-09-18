//
//  NJRSoundDevice.h
//  Pester
//
//  Created by Nicholas Riley on 3/8/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>

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

- (AudioDeviceID)deviceID;

+ (BOOL)volumeIsNotMutedOrInvalid:(float)volume;

@end
