//
//  PSAlarms.m
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarms.h"
#import "PSAlarm.h"

NSString * const PSAlarmsDidChangeNotification = @"PSAlarmsDidChangeNotification";
NSString * const PSAlarmsNextAlarmDidChangeNotification = @"PSAlarmsNextAlarmDidChangeNotification";

static NSString * const PSPendingAlarms = @"Pester pending alarms"; // NSUserDefaults key

static PSAlarms *PSAlarmsAllAlarms = nil;

@interface PSAlarms (Private)

- (void)_updateNextAlarm;

@end

@implementation PSAlarms

+ (void)setUp;
{
    if (PSAlarmsAllAlarms == nil) {
        PSAlarmsAllAlarms = [[self alloc] init];
        [PSAlarmsAllAlarms _updateNextAlarm]; // only generate notifications after singleton established
    }
}

+ (PSAlarms *)allAlarms;
{
    NSAssert(PSAlarmsAllAlarms != nil, @"Attempt to use +[PSAlarms allAlarms] before setup complete");
    return PSAlarmsAllAlarms;
}

- (void)_updateNextAlarm;
{
    NSEnumerator *e;
    PSAlarm *alarm, *oldNextAlarm = nextAlarm;
    [nextAlarm release];
    nextAlarm = nil;
    // sort alarms so earliest is first
    [alarms sortUsingSelector: @selector(compare:)];
    // find first un-expired alarm
    e = [alarms objectEnumerator];
    while ( (alarm = [e nextObject]) != nil) {
        if ([alarm isValid]) {
            nextAlarm = [alarm retain];
            break;
        }
    }
    if (oldNextAlarm != nextAlarm)
        [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmsNextAlarmDidChangeNotification object: nextAlarm];
}

- (id)init;
{
    if ( (self = [super init]) != nil) {
        alarms = [[NSMutableArray alloc] init];
        NS_DURING
            NSArray *alarmsData = [[NSUserDefaults standardUserDefaults] arrayForKey: PSPendingAlarms];
            NSEnumerator *e = [alarmsData objectEnumerator];
            NSData *alarmData;
            PSAlarm *alarm;
            while ( (alarmData = [e nextObject]) != nil) {
                alarm = [NSUnarchiver unarchiveObjectWithData: alarmData];
                if (alarm != nil)
                    [alarms addObject: alarm];
            }
        NS_HANDLER
            // XXX need better error handling here, don't stomp on data
            NSLog(@"An error occurred while attempting to restore the alarm list: %@", localException);
        NS_ENDHANDLER
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmTimerSet:) name: PSAlarmTimerSetNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmTimerExpired:) name: PSAlarmTimerExpiredNotification object: nil];
    }
    return self;
}

- (void)dealloc;
{
    [alarms release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

- (void)_changed;
{
    NSMutableArray *alarmsData = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSEnumerator *e;
    PSAlarm *alarm;
    [self _updateNextAlarm];
    // NSLog(@"PSAlarms _changed:\n%@", alarms);
    // archive
    e = [alarms objectEnumerator];
    while ( (alarm = [e nextObject]) != nil) {
        [alarmsData addObject: [NSArchiver archivedDataWithRootObject: alarm]];
    }
    [defaults setObject: alarmsData forKey: PSPendingAlarms];
    [defaults synchronize];
    [alarmsData release];
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmsDidChangeNotification object: self];
}

- (void)_alarmTimerExpired:(NSNotification *)notification;
{
    [alarms removeObject: [notification object]];
    [self _changed];
}

- (void)_alarmTimerSet:(NSNotification *)notification;
{
    [alarms addObject: [notification object]];
    [self _changed];
}

- (PSAlarm *)nextAlarm;
{
    return nextAlarm;
}

- (int)alarmCount;
{
    return [alarms count];
}

- (PSAlarm *)alarmAtIndex:(int)index;
{
    return [alarms objectAtIndex: index];
}

- (void)removeAlarmAtIndex:(int)index;
{
    [(PSAlarm *)[alarms objectAtIndex: index] cancel];
    [alarms removeObjectAtIndex: index];
}

- (void)removeAlarmsAtIndices:(NSArray *)indices;
{
    NSEnumerator *e = [indices objectEnumerator];
    NSNumber *n;
    int indexCount = [indices count], i = 0, alarmIndex;
    int *indexArray = (int *)malloc(indexCount * sizeof(int));
    NS_DURING
        while ( (n = [e nextObject]) != nil) {
            alarmIndex = [n intValue];
            [(PSAlarm *)[alarms objectAtIndex: alarmIndex] cancel];
            indexArray[i] = alarmIndex;
            i++;
        }
        [alarms removeObjectsFromIndices: indexArray numIndices: indexCount];
        [self _changed];
    NS_HANDLER
        free(indexArray);
        [self _changed];
        [localException raise];
    NS_ENDHANDLER
}

@end
