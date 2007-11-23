//
//  PSTimer.m
//  Pester
//
//  Created by Nicholas Riley on Sun Jan 05 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSTimer.h"
#import "PSAlarm.h"
#import "PSPowerManager.h"

NSTimer *PSTimerCurrent = nil;
PSTimer *PSTimerOnWake = nil;
NSMutableArray *PSTimerAllTimers = nil;

@interface PSTimer (Private)
+ (void)_schedule;
@end

@implementation PSTimer

+ (void)setUp;
{
    static PSPowerManager *powerManager;

    if (powerManager == nil) {
        powerManager = [[PSPowerManager alloc] initWithDelegate: self];
        PSTimerAllTimers = [[NSMutableArray alloc] init];
    }
}

+ (void)_schedule;
{
    NSDate *aboutNow = [NSDate dateWithTimeIntervalSinceNow: 0.1];
    [PSTimerCurrent invalidate]; [PSTimerCurrent release]; PSTimerCurrent = nil;
    PSTimerOnWake = nil;
    if ([PSTimerAllTimers count] > 0) {
        PSTimer *timer = nil;
        NSEnumerator *e;
        [PSTimerAllTimers sortUsingSelector: @selector(compare:)];
        // NSLog(@"_schedule: timers %@", [PSTimerAllTimers description]);
        e = [PSTimerAllTimers objectEnumerator];
        while ( (timer = [e nextObject]) != nil) {
            if ([timer isWakeUp]) {
                PSTimerOnWake = timer;
                // NSLog(@"scheduling wake timer %@", timer);
                break;
            }
        }
        e = [PSTimerAllTimers objectEnumerator];
        while ( (timer = [e nextObject]) != nil) {
            if ([[timer fireDate] compare: aboutNow] != NSOrderedDescending) {
                [timer performSelector: @selector(_timerExpired) withObject: nil afterDelay: 0];
                return;
            } else {
                NSTimeInterval ti = [[timer fireDate] timeIntervalSinceNow];
                if (ti > 0.1) {
                    PSTimerCurrent = [[NSTimer scheduledTimerWithTimeInterval: ti target: timer selector: @selector(_timerExpired) userInfo: nil repeats: NO] retain];
                    // NSLog(@"setting timer: %@", PSTimerCurrent);
                } else {
                    // NSLog(@"timer would have been too fast, setting: %@", timer);
                    [timer performSelector: @selector(_timerExpired) withObject: nil afterDelay: 0];
                }
                return;
            }
        }
        NSAssert(NO, @"shouldn't get here");
    } else {
        // NSLog(@"_schedule: no timers");
    }
}

+ (void)_timerAdded:(PSTimer *)timer;
{
    NSAssert1([PSTimerAllTimers indexOfObject: timer] == NSNotFound, @"PSTimerAllTimers already contains %@", timer);
    [PSTimerAllTimers addObject: timer];
    [self _schedule];
}

+ (void)_timerDeleted:(PSTimer *)timer;
{
    NSAssert1([PSTimerAllTimers indexOfObject: timer] != NSNotFound, @"PSTimerAllTimers does not contain %@", timer);
    [PSTimerAllTimers removeObject: timer];
    [self _schedule];
}

#pragma mark private

- (void)_setFireDate:(NSDate *)date;
{
    if (fireDate != date) {
        [fireDate release];
        fireDate = [date retain];
        if (fireDate != nil) {
            isValid = YES;
        }
    }
}

- (void)_setFireDateFromInterval;
{
    [self _setFireDate: [NSDate dateWithTimeIntervalSinceNow: timeInterval]];
}

- (void)_invalidate;
{
    if (isValid) {
        isValid = NO;
        [[self class] _timerDeleted: self];
    }
}

- (void)_timerExpired;
{
    if (!isValid) return; // in case the timer went off after we were invalidated
    [self retain]; // make sure we’re still accessible during the invocation
    // NSLog(@"timer expired: %@", self);
    if (repeats) {
        [invocation invoke];
        if (isValid) {
            [self _setFireDateFromInterval];
            [[self class] _schedule];
            // NSLog(@"timer repeats: %@", self);
        }
    } else {
        [self _invalidate];
        [invocation invoke];
    }
    [self release];
}

#pragma mark initialize-release

- (id)initWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)anObject repeats:(BOOL)yesOrNo;
{
    if ( (self = [self init]) != nil) {
        invocation = [[NSInvocation invocationWithMethodSignature:
            [aTarget methodSignatureForSelector: aSelector]] retain];
        [invocation setSelector: aSelector];
        [invocation setTarget: aTarget];
        [invocation setArgument: &self atIndex: 2];
        userInfo = [anObject retain];
        repeats = yesOrNo;
        timeInterval = ti;
        // don't do this or we leak: [invocation retainArguments];
        [aTarget retain]; // mimics retain behavior
        [self _setFireDateFromInterval];
        [[self class] _timerAdded: self]; // mimics runloop retention behavior
    }
    return self;
}

+ (PSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)anObject repeats:(BOOL)yesOrNo;
{
    PSTimer *timer = [[self alloc] initWithTimeInterval: ti target: aTarget selector: aSelector userInfo: anObject repeats: yesOrNo];
    [timer release];
    return timer;
}

- (void)dealloc;
{
    // NSLog(@"DEALLOC %@", self);
    isValid = NO;
    [fireDate release]; fireDate = nil;
    [[invocation target] release];
    [invocation release]; invocation = nil;
    [userInfo release]; userInfo = nil;
    [super dealloc];
}

#pragma mark accessing

- (NSDate *)fireDate;
{
    return fireDate;
}

- (void)invalidate;
{
    repeats = NO;
    [self _invalidate];
}

- (BOOL)isValid;
{
    return isValid;
}

- (id)userInfo;
{
    return userInfo;
}

- (BOOL)isWakeUp;
{
    return isWakeUp;
}

- (void)setWakeUp:(BOOL)doWake;
{
    isWakeUp = doWake;
}

- (NSComparisonResult)compare:(PSTimer *)other;
{
    return [fireDate compare: [other fireDate]];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"%@: at %@ do %@ on %@", [super description], [self fireDate], NSStringFromSelector([invocation selector]), [[invocation target] class]];
}

@end

@implementation PSTimer (PSPowerManagerDelegate)

+ (void)_runScheduledWakeErrorPanel:(NSString *)error;
{
    NSRunAlertPanel(NSLocalizedString(@"Can't schedule wake from sleep", "Wake timer set failure panel title"), NSLocalizedString(@"Pester is unable to set this computer to wake up at a later date (%@)", "Wake timer set failure panel message"), NSLocalizedString(@"Sleep", "Wake timer set failure panel button"), nil, nil, error);
}

+ (BOOL)powerManagerShouldIdleSleep:(PSPowerManager *)powerManager;
{
    [PSTimerCurrent invalidate];
    if (PSTimerOnWake != nil) {
        NSDate *date = [PSTimerOnWake fireDate];
        // NSLog(@"%lf sec remain until alarm", [date timeIntervalSinceNow]);
        if ([date timeIntervalSinceNow] > 30) {
            // NSLog(@"going to sleep, setting timer %@", PSTimerOnWake);
            NS_DURING
                [PSPowerManager setWakeTime: [[PSTimerOnWake fireDate] addTimeInterval: -15]];
            NS_HANDLER
                [self performSelectorOnMainThread: @selector(_runScheduledWakeErrorPanel:) withObject: [localException description] waitUntilDone: YES];
            NS_ENDHANDLER
            return YES;
        } else {
            // NSLog(@"not setting timer, will attempt to prevent idle sleep");
            return NO;
        }
    }
    return YES;
}

+ (void)powerManagerWillDemandSleep:(PSPowerManager *)powerManager;
{
    [self powerManagerShouldIdleSleep: powerManager];
}

+ (void)powerManagerDidWake:(PSPowerManager *)powerManager;
{
    if (PSTimerCurrent != nil) {
        [self _schedule];
    }
}

@end