//
//  NJRSoundDevice.m
//  Pester
//
//  Created by Nicholas Riley on 3/8/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "NJRSoundDevice.h"

NSString * const NJRSoundDeviceListChangedNotification = @"NJRSoundDeviceListChangedNotification";

static const UInt32 kLeftChannel = 0, kRightChannel = 1;

static NSMutableArray *allOutputDevices;
static NSMutableDictionary *devicesByID;
static NJRSoundDevice *defaultOutputDevice;

@interface NJRSoundDevice ()
+ (void)outputDeviceListChanged;
+ (void)defaultOutputDeviceChanged;
@end

static OSStatus AudioHardwareDevicesChanged(AudioObjectID objectID,
                                            UInt32 numberAddresses,
                                            const AudioObjectPropertyAddress addresses[],
                                            void *clientData) {
    if (objectID != kAudioObjectSystemObject)
        return paramErr;

    for (UInt32 addressIndex = 0 ; addressIndex < numberAddresses ; ++addressIndex) {
        switch (addresses[addressIndex].mSelector) {
            case kAudioHardwarePropertyDefaultOutputDevice:
            case kAudioHardwarePropertyDefaultSystemOutputDevice:
                [NJRSoundDevice defaultOutputDeviceChanged];
                break;
            case kAudioHardwarePropertyDevices:
                [NJRSoundDevice outputDeviceListChanged];
                break;
        }
    }

    return noErr;
}

static OSStatus AudioDeviceDataSourceChanged(AudioObjectID objectID,
                                             UInt32 numberAddresses,
                                             const AudioObjectPropertyAddress addresses[],
                                             void *clientData) {
    [NJRSoundDevice outputDeviceListChanged];

    return noErr;
}

@implementation NJRSoundDevice

+ (void)defaultOutputDeviceChanged;
{
    [defaultOutputDevice release];
    defaultOutputDevice = nil;
}

+ (void)outputDeviceListChanged;
{
    [self defaultOutputDeviceChanged];
    [devicesByID release];
    devicesByID = nil;
    // since we can't control the lifetime entirely, we may not release in the expected order
    [allOutputDevices makeObjectsPerformSelector:@selector(unregisterSourceListener)];
    [allOutputDevices release];
    allOutputDevices = nil;
    [NJRSoundDevice allOutputDevices];
    [[NSNotificationCenter defaultCenter] postNotificationName: NJRSoundDeviceListChangedNotification object: allOutputDevices];
}

- (NJRSoundDevice *)initWithAudioDeviceID:(AudioDeviceID)audioDeviceID;
{
    if ( (self = [super init]) == nil)
	return nil;
	
    deviceID = audioDeviceID;
    savedChannelVolume[kLeftChannel] = savedChannelVolume[kRightChannel] = -1;

    // is it an output device?
    UInt32 propertySize;
    OSStatus err;
    AudioObjectPropertyAddress propertyAddress = {
	kAudioDevicePropertyStreamConfiguration,
	kAudioDevicePropertyScopeOutput,
	kAudioObjectPropertyElementWildcard };

    // get number of output channels
    UInt32 outputChannelCount = 0;
    err = AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, NULL, &propertySize);
    if (err != noErr || propertySize == 0) {
	[self release];
	return nil;
    }
    AudioBufferList *bufferList = malloc(propertySize);
    if (bufferList == NULL) {
	[self release];
	return nil;
    }
    err = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, bufferList);
    if (err != noErr) {
	free(bufferList);
	[self release];
	return nil;
    }
    for (int i = 0 ; i < bufferList->mNumberBuffers ; i++)
	outputChannelCount += bufferList->mBuffers[i].mNumberChannels;
    free(bufferList);

    if (outputChannelCount == 0) {
	[self release];
	return nil;
    }

    // get device name
    propertyAddress.mSelector = kAudioObjectPropertyName;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    propertySize = sizeof(CFStringRef);
    err = AudioObjectGetPropertyData(audioDeviceID, &propertyAddress, 0, NULL, &propertySize, (CFStringRef *)&name);
    if (err != noErr) {
	[self release];
	return nil;
    }

    // prefer (optional) device's currently selected data source name
    // e.g. 'Headphones', or name of AirPlay device
    propertyAddress.mSelector = kAudioDevicePropertyDataSource;
    propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
    UInt32 source;
    propertySize = sizeof(source);
    err = AudioObjectGetPropertyData(audioDeviceID, &propertyAddress, 0, NULL, &propertySize, &source);
    if (err == noErr) {
        err = AudioObjectAddPropertyListener(audioDeviceID, &propertyAddress, AudioDeviceDataSourceChanged, NULL);
        if (err != noErr)
            return nil;
        registeredSourceListener = YES;

        NSString *sourceName = nil;
        AudioValueTranslation translation = { &source, sizeof(source), &sourceName, sizeof(CFStringRef) };
        propertyAddress.mSelector = kAudioDevicePropertyDataSourceNameForIDCFString;
        propertySize = sizeof(translation);
        err = AudioObjectGetPropertyData(audioDeviceID, &propertyAddress, 0, NULL, &propertySize, &translation);
        if (err == noErr) {
            [name release];
            name = sourceName;
        }
    }

    // get device UID
    propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertySize = sizeof(CFStringRef);
    err = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &propertySize, &uid);
    if (err != noErr) {
	[self release];
	return nil;
    }

    // get stereo channel IDs (so we can try to set their volume)
    propertyAddress.mSelector = kAudioDevicePropertyPreferredChannelsForStereo;
    propertyAddress.mScope = kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    propertySize = sizeof(stereoChannels);
    err = AudioObjectGetPropertyData(audioDeviceID, &propertyAddress, 0, NULL, &propertySize, &stereoChannels);
    canSetVolume = (err == noErr);
    if (!canSetVolume)
	return self;

    // can we set the volume?
    Boolean isSettable;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mElement = stereoChannels[kLeftChannel]; // XXX or set master volume?
    err = AudioObjectIsPropertySettable(audioDeviceID, &propertyAddress, &isSettable);
    canSetVolume = (err == noErr) && isSettable;
    if (!canSetVolume)
	return self;
    
    return self;
}

- (void)unregisterSourceListener;
{
    if (!registeredSourceListener)
        return;

    AudioObjectPropertyAddress propertyAddress = {
        kAudioDevicePropertyDataSource,
        kAudioDevicePropertyScopeOutput,
        kAudioObjectPropertyElementMaster
    };
    AudioObjectRemovePropertyListener(deviceID, &propertyAddress, AudioDeviceDataSourceChanged, NULL);

    registeredSourceListener = NO;
}

- (void)dealloc;
{
    [name release];
    [self unregisterSourceListener];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"<NJRSoundDevice '%@'%@>", name, canSetVolume ? @" can set volume" : @""];
}

- (NSString *)name;
{
    return name;
}

- (NSString *)uid;
{
    return uid;
}

- (AudioDeviceID)deviceID;
{
    return deviceID;
}

- (BOOL)canSetVolume;
{
    return canSetVolume;
}

+ (NSArray *)allOutputDevices;
{
    if (allOutputDevices != nil)
	return allOutputDevices;
    
    OSStatus err;
    AudioObjectPropertyAddress propertyAddress = {
	kAudioHardwarePropertyDevices,
	kAudioObjectPropertyScopeGlobal,
	kAudioObjectPropertyElementMaster };
    
    static BOOL registeredPropertyListener = NO;
    if (!registeredPropertyListener) {
        err = AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, AudioHardwareDevicesChanged, NULL);
        if (err != noErr)
            return nil;
        propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
        err = AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, AudioHardwareDevicesChanged, NULL);
        if (err != noErr)
            return nil;
        propertyAddress.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice;
        AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, AudioHardwareDevicesChanged, NULL);
        if (err != noErr)
            return nil;
        propertyAddress.mSelector = kAudioHardwarePropertyDevices;
        registeredPropertyListener = YES;
    }

    UInt32 propertySize;
    err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize);
    if (err != noErr)
	return nil;
    
    int deviceCount = propertySize / sizeof(AudioDeviceID);
    AudioDeviceID *deviceIDs = malloc(propertySize);
    if (deviceIDs == NULL)
	return nil;
    
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, deviceIDs);
    if (err != noErr) {
	free(deviceIDs);
	return nil;
    }
    
    allOutputDevices = [[NSMutableArray alloc] initWithCapacity: deviceCount];
    devicesByID = [[NSMutableDictionary alloc] initWithCapacity: deviceCount];
    for (int i = 0 ; i < deviceCount ; i++) {
	NJRSoundDevice *device = [[NJRSoundDevice alloc] initWithAudioDeviceID: deviceIDs[i]];
	if (device == nil)
	    continue;
	[allOutputDevices addObject: device];
	[devicesByID setObject: device forKey: [NSNumber numberWithUnsignedInt: deviceIDs[i]]];
	[device release];
    }
    free(deviceIDs);
    
    return allOutputDevices;
}

+ (NJRSoundDevice *)defaultOutputDevice;
{
    if (defaultOutputDevice != nil) {
	// check for device disappearance - XXX move somewhere else?
	if ([devicesByID objectForKey: [NSNumber numberWithUnsignedInt: defaultOutputDevice->deviceID]] == defaultOutputDevice)
	    return defaultOutputDevice;
	[defaultOutputDevice release];
	defaultOutputDevice = nil;
    }

    UInt32 propertySize;
    OSStatus err;
    AudioDeviceID deviceID;
    
    if (devicesByID == nil)
	[self allOutputDevices];
    
    AudioObjectPropertyAddress propertyAddress = {
	kAudioHardwarePropertyDefaultSystemOutputDevice,
	kAudioObjectPropertyScopeGlobal,
	kAudioObjectPropertyElementMaster };    
    propertySize = sizeof(deviceID);
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, &deviceID);
    if (err != noErr)
	return nil;
    
    return [devicesByID objectForKey: [NSNumber numberWithUnsignedInt: deviceID]];
}

+ (NJRSoundDevice *)setDefaultOutputDeviceByUID:(NSString *)uid;
{
    if ([[defaultOutputDevice uid] isEqualToString: uid])
	return defaultOutputDevice;

    [defaultOutputDevice release];
    defaultOutputDevice = nil;

    if (uid == nil)
	return nil;

    UInt32 propertySize;
    OSStatus err;
    AudioDeviceID deviceID;
    AudioValueTranslation translation = { &uid, sizeof(uid), &deviceID, sizeof(deviceID) };

    if (devicesByID == nil)
	[self allOutputDevices];

    AudioObjectPropertyAddress propertyAddress = {
	kAudioHardwarePropertyDeviceForUID,
	kAudioObjectPropertyScopeGlobal,
	kAudioObjectPropertyElementMaster };
    propertySize = sizeof(translation);
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &propertySize, &translation);
    if (err != noErr)
	return nil;

    defaultOutputDevice = [[devicesByID objectForKey: [NSNumber numberWithUnsignedInt: deviceID]] retain];

    return defaultOutputDevice;
}

- (QTAudioContextRef)quickTimeAudioContext;
{
    QTAudioContextRef audioContext;
    OSStatus err = QTAudioContextCreateForAudioDevice(kCFAllocatorDefault, (CFStringRef)uid, NULL, &audioContext);

    if (err != noErr)
	return NULL;

    return (QTAudioContextRef)[(id)audioContext autorelease];
}

- (BOOL)getOutputVolume:(float *)volume;
{
    UInt32 propertySize;
    OSStatus err;
    
    // read the current volume scalar settings [0...1]
    propertySize = sizeof(float);
    err = AudioDeviceGetProperty(deviceID, stereoChannels[kLeftChannel], false, kAudioDevicePropertyVolumeScalar, &propertySize, &channelVolume[kLeftChannel]);
    if (err != noErr) return NO;
    err = AudioDeviceGetProperty(deviceID, stereoChannels[kRightChannel], false, kAudioDevicePropertyVolumeScalar, &propertySize, &channelVolume[kRightChannel]);
    if (err != noErr) return NO;
    if (volume != NULL) *volume = MAX(channelVolume[kLeftChannel], channelVolume[kRightChannel]);
    return YES;
}

- (void)_updateChannelVolume;
{
    UInt32 propertySize = sizeof(channelVolume[kLeftChannel]);
    // ignore errors
    AudioDeviceSetProperty(deviceID, NULL, stereoChannels[kLeftChannel], false, kAudioDevicePropertyVolumeScalar, propertySize, &channelVolume[kLeftChannel]);
    AudioDeviceSetProperty(deviceID, NULL, stereoChannels[kRightChannel], false, kAudioDevicePropertyVolumeScalar, propertySize, &channelVolume[kRightChannel]);
}

- (BOOL)saveOutputVolume;
{
    if (![self getOutputVolume: NULL]) return NO;
    savedChannelVolume[kLeftChannel] = channelVolume[kLeftChannel];
    savedChannelVolume[kRightChannel] = channelVolume[kRightChannel];
    // NSLog(@"saving channel volume {%f, %f}", channelVolume[kLeftChannel],channelVolume[kRightChannel]);
    return YES;
}

- (void)setOutputVolume:(float)volume;
{
    if (!canSetVolume) return;
    
    channelVolume[kLeftChannel] = volume;
    channelVolume[kRightChannel] = volume;
    [self _updateChannelVolume];
}

- (void)restoreSavedOutputVolume;
{
    if (savedChannelVolume[kLeftChannel] < 0) return;
    // NSLog(@"restoring saved channel volume");
    channelVolume[kLeftChannel] = savedChannelVolume[kLeftChannel];
    channelVolume[kRightChannel] = savedChannelVolume[kRightChannel];
    savedChannelVolume[kLeftChannel] = -1;
    savedChannelVolume[kRightChannel] = -1;
    [self _updateChannelVolume];
}

- (void)restoreSavedOutputVolumeIfCurrently:(float)volume;
{
    float currentVolume;
    if ([self getOutputVolume: &currentVolume] && abs(volume - currentVolume) < 0.05) {
        [self restoreSavedOutputVolume];
    }
}

@end
