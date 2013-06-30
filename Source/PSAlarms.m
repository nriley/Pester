//
//  PSAlarms.m
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarms.h"
#import "PSAlarm.h"
#import "PSTimer.h"
#import "NSDictionary-NJRExtensions.h"

NSString * const PSAlarmImportException = @"PSAlarmImportException";

NSString * const PSAlarmsDidChangeNotification = @"PSAlarmsDidChangeNotification";
NSString * const PSAlarmsNextAlarmDidChangeNotification = @"PSAlarmsNextAlarmDidChangeNotification";

// NSUserDefaults keys
static NSString * const PSPendingAlarms = @"Pester pending alarms"; // 1.0 Ð 1.1a3
static NSString * const PSAllAlarms = @"Pester alarms"; // 1.1a4 Ð 

// property list keys
static NSString * const PLAlarmsPending = @"pending";
static NSString * const PLAlarmsExpired = @"expired";

static PSAlarms *PSAlarmsAllAlarms = nil;

@interface PSAlarms (Private)

- (void)_updateNextAlarm;

@end

@implementation PSAlarms

+ (void)setUp;
{
    [PSTimer setUp];
    if (PSAlarmsAllAlarms == nil) {
        NSDictionary *plAlarms = [[NSUserDefaults standardUserDefaults] objectForKey: PSAllAlarms];
        if (plAlarms == nil) {
            PSAlarmsAllAlarms = [[self alloc] init];
        } else {
            PSAlarmsAllAlarms = [[self alloc] initWithPropertyList: plAlarms];
        }
        [PSAlarmsAllAlarms _updateNextAlarm]; // only generate notifications after singleton established
    }
}

+ (PSAlarms *)allAlarms;
{
    NSAssert(PSAlarmsAllAlarms != nil, @"Attempt to use +[PSAlarms allAlarms] before setup complete");
    return PSAlarmsAllAlarms;
}

#pragma mark private

- (void)_changed;
{
    NSMutableArray *alarmsData = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self _updateNextAlarm];
    // NSLog(@"PSAlarms _changed:\n%@", alarms);
    [defaults setObject: [self propertyListRepresentation] forKey: PSAllAlarms];
    [defaults synchronize];
    [alarmsData release];
    [[NSNotificationCenter defaultCenter] postNotificationName: PSAlarmsDidChangeNotification object: self];
}

- (void)_alarmTimerExpired:(NSNotification *)notification;
{
    PSAlarm *alarm = [notification object];
    // NSLog(@"timer expired: %@ retainCount %d", alarm, [alarm retainCount]);
    [expiredAlarms addObject: alarm];
    // NSLog(@"expired alarms: %@", [expiredAlarms description]);
    [alarms removeObject: alarm];
    [self _changed];
}

- (void)_alarmTimerSet:(NSNotification *)notification;
{
    PSAlarm *alarm = [notification object];
    // NSLog(@"timer set: %@ retainCount %d", alarm, [alarm retainCount]);
    [alarms addObject: alarm];
    [expiredAlarms removeObject: alarm];
    [self _changed];
}

- (void)_alarmDied:(NSNotification *)notification;
{
    PSAlarm *alarm = [notification object];
    // NSLog(@"alarm died: %@ retainCount %d", alarm, [alarm retainCount]);
    [alarms removeObject: alarm];
    [expiredAlarms removeObject: alarm];
    [self _changed];
}

- (void)_updateNextAlarm;
{
    NSEnumerator *e;
    PSAlarm *alarm, *oldNextAlarm = nextAlarm;
    [nextAlarm release];
    nextAlarm = nil;
    // sort alarms so earliest is first
    [alarms sortUsingSelector: @selector(compareDate:)];
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

- (void)_setUpNotifications;
{
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmTimerSet:) name: PSAlarmTimerSetNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmTimerExpired:) name: PSAlarmTimerExpiredNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_alarmDied:) name: PSAlarmDiedNotification object: nil];
}

#pragma mark initialize-release

- (id)init;
{
    if ( (self = [super init]) != nil) {
        alarms = [[NSMutableArray alloc] init];
        expiredAlarms = [[NSMutableSet alloc] init];
        [self _setUpNotifications];
    }
    return self;
}

- (void)dealloc;
{
    [alarms release];
    [expiredAlarms release];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

#pragma mark accessing

- (NSArray *)alarms;
{
    return alarms;
}

- (PSAlarm *)nextAlarm;
{
    return nextAlarm;
}

- (int)alarmCount;
{
    return [alarms count];
}

- (PSAlarm *)alarmAtIndex:(int)alarmIndex;
{
    return [alarms objectAtIndex: alarmIndex];
}

- (void)removeAlarmAtIndex:(int)alarmIndex;
{
    [(PSAlarm *)[alarms objectAtIndex: alarmIndex] cancelTimer];
    [alarms removeObjectAtIndex: alarmIndex];
}

- (void)removeAlarms:(NSSet *)alarmsToRemove;
{
    NSIndexSet *indexes = [alarms indexesOfObjectsPassingTest:
                           ^BOOL(id alarm, NSUInteger i, BOOL *stop) {
                               return [alarmsToRemove containsObject: alarm];
                           }];
    [alarmsToRemove makeObjectsPerformSelector: @selector(cancelTimer)];
    [alarms removeObjectsAtIndexes: indexes];
    [self _changed];
}

- (void)restoreAlarms:(NSSet *)alarmsToRestore;
{
    [alarmsToRestore makeObjectsPerformSelector: @selector(resetTimer)];
}

- (BOOL)alarmsExpiring;
{
    return [expiredAlarms count] != 0;
}

#pragma mark printing

- (NSString *)description;
{
    return [NSString stringWithFormat: @"%@ pending %@\n%@\n",
        [super description], alarms,
        [expiredAlarms count] > 0 ? [NSString stringWithFormat: @"expired %@\n", expiredAlarms]
                                  : @""];
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableArray *plPendingAlarms = [[NSMutableArray alloc] initWithCapacity: [alarms count]];
    NSMutableArray *plExpiredAlarms = [[NSMutableArray alloc] initWithCapacity: [expiredAlarms count]];
    NSDictionary *plAllAlarms, *plAlarm;
    NSEnumerator *e;
    PSAlarm *alarm;

    e = [alarms objectEnumerator];
    while ( (alarm = [e nextObject]) != nil) {
        plAlarm = [alarm propertyListRepresentation];
        if (plAlarm != nil)
            [plPendingAlarms addObject: plAlarm];
    }

    e = [expiredAlarms objectEnumerator];
    while ( (alarm = [e nextObject]) != nil) {
        plAlarm = [alarm propertyListRepresentation];
        if (plAlarm != nil)
            [plExpiredAlarms addObject: plAlarm];
    }
    
    plAllAlarms = [NSDictionary dictionaryWithObjectsAndKeys:
        plPendingAlarms, PLAlarmsPending, plExpiredAlarms, PLAlarmsExpired, nil];
    [plPendingAlarms release];
    [plExpiredAlarms release];

    return plAllAlarms;
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [super init]) != nil) {
        NSArray *plPendingAlarms = [dict objectForRequiredKey: PLAlarmsPending];
        NSArray *plExpiredAlarms = [dict objectForRequiredKey: PLAlarmsExpired];
        NSEnumerator *e;
        NSDictionary *plAlarm;
        PSAlarm *alarm;

        alarms = [[NSMutableArray alloc] initWithCapacity: [plPendingAlarms count]];
        e = [plPendingAlarms objectEnumerator];
        while ( (plAlarm = [e nextObject]) != nil) {
	    alarm = [[PSAlarm alloc] initWithPropertyList: plAlarm];
            [alarms addObject: alarm];
	    [alarm release];
        }

        e = [plExpiredAlarms objectEnumerator];
        while ( (plAlarm = [e nextObject]) != nil) {
            // expired alarms may be ready for deletion, or may repeat - if the latter, PSAlarm will reschedule the alarm so the repeat interval begins at restoration time. 
            if ( (alarm = [[PSAlarm alloc] initWithPropertyList: plAlarm]) != nil) {
                [alarms addObject: alarm];
		[alarm release];
	    }
        }
        expiredAlarms = [[NSMutableSet alloc] init];
        
        [self _setUpNotifications];
    }
    return self;
}

#pragma mark archiving (Pester 1.0)

- (unsigned)countOfVersion1Alarms;
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey: PSPendingAlarms] count];
}

- (void)discardVersion1Alarms;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey: PSPendingAlarms];
    [defaults synchronize];
}

- (void)importVersion1Alarms;
{
    NSArray *alarmsData = [[NSUserDefaults standardUserDefaults] arrayForKey: PSPendingAlarms];
    NSEnumerator *e = [alarmsData objectEnumerator];
    NSData *alarmData;
    PSAlarm *alarm;
    NSMutableArray *importedAlarms = [[NSMutableArray alloc] initWithCapacity: [alarmsData count]];
    @try {
	while ( (alarmData = [e nextObject]) != nil) {
	    alarm = [NSUnarchiver unarchiveObjectWithData: alarmData];
	    if (alarm == nil)
		@throw [NSException exceptionWithName: NSInternalInconsistencyException reason: @"Failed to decode Pester 1.0 alarm." userInfo: nil];
	    [importedAlarms addObject: alarm];
	    if (![alarm setTimer]) // expired
		[alarms addObject: alarm];
	}
    } @catch (NSException *exception) {
	[self removeAlarms: [NSSet setWithArray: importedAlarms]];
	@throw;
    } @finally {
	[importedAlarms release];
    }
}

@end
