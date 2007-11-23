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

@implementation PSPowerManager

+ (BOOL)autoWakeSupported;
{
    // XXX imagine it's supported on all machines that support 10.4
    return YES;
}

+ (void)setWakeTime:(NSDate *)time;
{
    IOPMSchedulePowerEvent((CFDateRef)time, (CFStringRef)[[NSBundle mainBundle] bundleIdentifier], CFSTR(kIOPMAutoWake));
}

+ (void)clearWakeTime;
{
    // XXX implement (IOPMCancelScheduledPowerEvent)
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
        NSAssert(root_port != 0, @"IORegisterForSystemPower failed");

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