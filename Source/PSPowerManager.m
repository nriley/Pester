//
//  PSPowerManager.m
//  Pester
//
//  Created by Nicholas Riley on Mon Dec 23 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSPowerManager.h"

#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>
#import <CoreFoundation/CoreFoundation.h>

/*
 * Copyright (c) 2002 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 *
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.1 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 *
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

/* Sample code to set an automatic wakeup timer to wake machines from sleep.

When a machine is asleep, most hardware (including the processor) is
powered off. The PMU chip is one of the few things left powered on, and it's
able to generate a wakeup event on a timer.
This code shows how to set the wakeup timer within the PMU.
*/

// From autowake.cpp:

// #define kAppleVIAUserClientMagicCookie 0x101face // or 0x101beef -- for PMU
// #define kAppleVIAUserClientMagicCookie 0x101beef // or 0x101face  -- for PMU

// The difference is 101beef is only for superusers and 101face works for
// non-privileged users.  I have not determined which calls are only available
// for superusers

#define PMU_MAGIC_PASSWORD	0x0101FACE // BEEF

/* ==========================================
* Close a device user client
* =========================================== */
static kern_return_t
closeDevice(io_connect_t con)
{
    kern_return_t ret = IOServiceClose(con);

    NSCAssert1(ret == kIOReturnSuccess, @"closeDevice: IOServiceClose returned an error of type %08lx", (unsigned long)ret);

    return ret;
}

/* ==========================================
* Open an IORegistry device user client
* =========================================== */
static void
openDevice(io_object_t obj, unsigned int type, io_connect_t * con)
{
    kern_return_t ret = IOServiceOpen(obj, mach_task_self(), type, con);

    NSCAssert1(ret == kIOReturnSuccess, @"openDevice: IOServiceOpen returned an error of type %08lx", (unsigned long)ret);
}

/* ===========================================
* Changes the string for a registry
* property.
* ===========================================  */
void
writeDataProperty(io_object_t handle, CFStringRef name,
                  unsigned char * bytes, unsigned int size)
{
    kern_return_t kr = kIOReturnNoMemory;
    CFDataRef data;
    CFMutableDictionaryRef dict = 0;

    data = CFDataCreate(kCFAllocatorDefault, bytes, size);
    NSCAssert(data != NULL, @"writeDataProperty: CFDataCreate failed");
    [(NSData *)data autorelease];

    dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    NSCAssert(data != NULL, @"writeDataProperty: CFDictionaryCreateMutable failed");
    [(NSMutableDictionary *)dict autorelease];

    CFDictionarySetValue(dict, name, data);
    kr = IOConnectSetCFProperties(handle, dict);
    NSCAssert1(kr == KERN_SUCCESS, @"writeDataProperty: IOConnectSetCFProperties returned an error of type %08lx", (unsigned long)kr);
}

/* ==========================================
* Write a data property to the PMU driver
* Arguments
*     pmuReference - the IORegistry device to write to
*     propertyName - Name of the property to write to
*     data - Data to write
*     dataSize - Data size
* =========================================== */
void
writePMUProperty(io_object_t pmuReference, CFStringRef propertyName, void *data, size_t dataSize)
{
    io_connect_t conObj;
    openDevice(pmuReference, PMU_MAGIC_PASSWORD, &conObj);
    writeDataProperty(conObj, propertyName, (unsigned char *)data, dataSize);
    closeDevice(conObj);
}


/* ==========================================
* Look through the registry and search for an
* IONetworkInterface objects with the given
* name.
* If a match is found, the object is returned.
* =========================================== */

io_service_t
getInterfaceWithName(mach_port_t masterPort, char *className)
{
    io_service_t obj;

    obj = IOServiceGetMatchingService(masterPort, IOServiceMatching(className));

    NSCAssert(obj != NULL, @"getInterfaceWithName: IOServiceGetMatchingService returned NULL");

    return obj;
}

/* ==========================================
* Find the PMU in the IORegistry
* =========================================== */
io_service_t
openPMUComPort(void)
{
    static mach_port_t masterPort;
    kern_return_t kr;

    // Get a master port to talk with the mach_kernel
    kr = IOMasterPort(bootstrap_port, &masterPort);
    NSCAssert1(kr == KERN_SUCCESS, @"openPMUComPort: IOMasterPort returned an error of type %08lx", (unsigned long)kr);

    return getInterfaceWithName(masterPort, "ApplePMU");
}


/* ==========================================
* Release our reference to the PMU in the IORegistry
* =========================================== */
void
closePMUComPort(io_object_t pmuRef)
{
    IOObjectRelease(pmuRef);
}

@implementation PSPowerManager

+ (BOOL)autoWakeSupported;
{
    io_service_t pmuReference = openPMUComPort();
    if (pmuReference == NULL) return NO;
    closePMUComPort(pmuReference);
    return YES;
}

+ (io_service_t)_pmuReference;
{
    io_service_t pmuReference = openPMUComPort();
    NSAssert(pmuReference != NULL, NSLocalizedString(@"Couldn't find PMU in IORegistry. This computer may not support automatic wake from sleep.", "Assertion message: couldn't open ApplePMU"));
    return pmuReference;
}

+ (NSDate *)wakeTime;
{
    io_service_t pmuReference = [self _pmuReference];
    NSNumber *autoWakeTime;
    unsigned long long rawWakeTime;
    
    autoWakeTime = (NSNumber *)IORegistryEntryCreateCFProperty(pmuReference, CFSTR("AutoWake"), NULL, 0);
    closePMUComPort(pmuReference);

    if (autoWakeTime == nil) return nil;
    rawWakeTime = [autoWakeTime unsignedLongLongValue];
    if (rawWakeTime == 0) return nil;
    // XXX no idea what the epoch is supposed to be, but this works...
    return [NSDate dateWithTimeIntervalSinceReferenceDate: rawWakeTime - 18446744072475718320LLU];
}

+ (void)setWakeTime:(NSDate *)time;
{
    io_service_t pmuReference = [self _pmuReference];
    unsigned long wakeTime;

    if (time == nil) wakeTime = 0;
    else {
        wakeTime = [time timeIntervalSinceNow];
        if (wakeTime == 0) wakeTime++; // 0 will disable
    }
    writePMUProperty(pmuReference, CFSTR("AutoWake"), (unsigned long *)&wakeTime, sizeof(wakeTime));
    
    closePMUComPort(pmuReference);
}

+ (void)clearWakeTime;
{
    [self setWakeTime: nil];
}

// modified from RegisterForSleep sample code

- (void)_messageReceived:(natural_t)messageType withArgument:(void *)messageArgument;
{
    switch (messageType) {
        case kIOMessageSystemWillSleep:
            if ([delegate respondsToSelector: @selector(powerManagerWillDemandSleep:)]) {
                [delegate powerManagerWillDemandSleep: self];
                IOAllowPowerChange(root_port, (long)messageArgument);
            }
            break;
        case kIOMessageCanSystemSleep:
            if ([delegate respondsToSelector: @selector(powerManagerShouldIdleSleep:)]) {
                if ([delegate powerManagerShouldIdleSleep: self]) {
                    IOAllowPowerChange(root_port, (long)messageArgument);
                } else {
                    IOCancelPowerChange(root_port, (long)messageArgument);
                }
            }
            break;
        case kIOMessageSystemHasPoweredOn:
            if ([delegate respondsToSelector: @selector(powerManagerDidWake:)])
                [delegate powerManagerDidWake: self];
            break;
    }
}

void
powerCallback(void *refCon, io_service_t service, natural_t messageType, void *messageArgument)
{
    [(PSPowerManager *)refCon _messageReceived: messageType withArgument: messageArgument];
}

- (id)initWithDelegate:(id)aDelegate;
{
    if ( (self = [super init]) != nil) {
        IONotificationPortRef notificationPort;

        delegate = [aDelegate retain];
        root_port = IORegisterForSystemPower(self, &notificationPort, powerCallback, &notifier);
        NSAssert(root_port != NULL, @"IORegisterForSystemPower failed");

        CFRunLoopAddSource(CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopDefaultMode);
    }
    return self;
}

- (void)dealloc;
{
    IODeregisterForSystemPower(&notifier);
    [delegate release];
    [super dealloc];
}

@end