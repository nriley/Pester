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

static NSString * const PSPendingAlarms = @"Pester pending alarms"; // NSUserDefaults key

static PSAlarms *PSAlarmsAllAlarms = nil;

@implementation PSAlarms

+ (void)setUp; // XXX if you can think of a better name, please be my guest.
{
    if (PSAlarmsAllAlarms == nil) {
        PSAlarmsAllAlarms = [[self alloc] init];
    }
}

+ (PSAlarms *)allAlarms;
{
    return PSAlarmsAllAlarms;
}

- (id)init;
{
    if ( (self = [super init]) != nil) {
        NS_DURING
            NSData *alarmData = [[NSUserDefaults standardUserDefaults] dataForKey: PSPendingAlarms];
            if (alarmData != nil) {
                alarms = [[NSUnarchiver unarchiveObjectWithData: alarmData] retain];
            }
        NS_HANDLER
            // XXX need better error handling here, don't stomp on data
            NSLog(@"An error occurred while attempting to restore the alarm list: %@", localException);
        NS_ENDHANDLER
        if (alarms == nil) alarms = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmTimerSet:) name: PSAlarmTimerSetNotification object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmTimerExpired:) name: PSAlarmTimerExpiredNotification object: nil];
    }
    return self;
}

- (void)dealloc;
{
    [alarms dealloc];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

- (void)_changed;
{
    NSData *alarmData;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [alarms sortUsingSelector: @selector(compare:)];
    alarmData = [NSArchiver archivedDataWithRootObject: alarms];
    [defaults setObject: alarmData forKey: PSPendingAlarms];
    [defaults synchronize];
    // NSLog(@"PSAlarms changed: %@", alarms);
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
    [alarms removeObjectAtIndex: index];
}

- (void)removeAlarmsAtIndices:(NSArray *)indices;
{
    NSEnumerator *e = [indices objectEnumerator];
    NSNumber *n;
    int indexCount = [indices count], i = 0;
    int *indexArray = (int *)malloc(indexCount * sizeof(int));
    NS_DURING
        while ( (n = [e nextObject]) != nil) {
            indexArray[i] = [n intValue];
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
