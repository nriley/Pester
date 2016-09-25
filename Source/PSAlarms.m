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
static NSString * const PSPendingAlarms = @"Pester pending alarms"; // 1.0 - 1.1a3
static NSString * const PSAllAlarms = @"Pester alarms"; // 1.1a4 and later

// property list keys
static NSString * const PLAlarmsPending = @"pending";
static NSString * const PLAlarmsExpired = @"expired";

static PSAlarms *PSAlarmsAllAlarms = nil;

enum {
    PSAlarmsFailedToDeserializeError = 1
};

enum {
    PSAlarmsFailedToDeserializeQuitRecoveryOptionIndex = 0,
    PSAlarmsFailedToDeserializeStartOverRecoveryOptionIndex = 1
};

@interface PSAlarms (Private)

- (void)_changed;
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
            @try {
                PSAlarmsAllAlarms = JRThrowErr([[self alloc] initWithPropertyList: plAlarms error: jrErrRef]);
            } @catch (JRErrException *je) {
                NSAssert([NSApp presentError: [[JRErrContext currentContext] popError]], @"Error recovery failed");
                PSAlarmsAllAlarms = [[self alloc] init];
            }
        }
        [PSAlarmsAllAlarms _updateNextAlarm]; // only generate notifications after singleton established
        [PSAlarmsAllAlarms _changed]; // write back in case we changed anything while restoring
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
    [alarmsByUUID setObject: alarm forKey: [alarm uuid]];
    [expiredAlarms removeObject: alarm];
    [self _changed];
}

- (void)_alarmDied:(NSNotification *)notification;
{
    PSAlarm *alarm = [notification object];
    // NSLog(@"alarm died: %@ retainCount %d", alarm, [alarm retainCount]);
    [alarms removeObject: alarm];
    [alarmsByUUID removeObjectForKey: [alarm uuid]];
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

static NSMapTable *UUIDMapTableWithCapacity(NSUInteger capacity) {
    return [[NSMapTable alloc]
            initWithKeyOptions: NSPointerFunctionsOpaqueMemory | NSPointerFunctionsObjectPointerPersonality
            valueOptions: NSPointerFunctionsOpaqueMemory | NSPointerFunctionsObjectPersonality
            capacity: capacity];
}

- (id)init;
{
    if ( (self = [super init]) != nil) {
        alarms = [[NSMutableArray alloc] init];
        alarmsByUUID = UUIDMapTableWithCapacity(8);
        expiredAlarms = [[NSMutableSet alloc] init];
        [self _setUpNotifications];
    }
    return self;
}

- (void)dealloc;
{
    [alarms release];
    [alarmsByUUID release];
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

- (NSUInteger)alarmCount;
{
    return [alarms count];
}

- (PSAlarm *)alarmWithUUIDString:(NSString *)uuidString;
{
    CFUUIDRef uuid = CFUUIDCreateFromString(NULL, (CFStringRef)uuidString);
    PSAlarm *alarm = [alarmsByUUID objectForKey: (id)uuid];

    CFRelease(uuid);
    return alarm;
}

- (void)removeAlarms:(NSSet *)alarmsToRemove;
{
    NSIndexSet *indexes = [alarms indexesOfObjectsPassingTest:
                           ^BOOL(id alarm, NSUInteger i, BOOL *stop) {
                               return [alarmsToRemove containsObject: alarm];
                           }];
    [alarmsToRemove makeObjectsPerformSelector: @selector(cancelTimer)];
    for (id uuidToRemove in [alarmsToRemove valueForKey: @"uuid"])
        [alarmsByUUID removeObjectForKey: uuidToRemove];
    [alarms removeObjectsAtIndexes: indexes];
    [self _changed];
}

- (void)restoreAlarms:(NSSet *)alarmsToRestore;
{
    [alarmsToRestore makeObjectsPerformSelector: @selector(restoreTimer)];
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

- (void)addAlarmsWithPropertyList:(NSArray *)plAlarms;
{
    for (NSDictionary *plAlarm in plAlarms) {
        __block PSAlarm *alarm = nil;
        @try {
            JRThrowErr(alarm = [[PSAlarm alloc] initWithPropertyList: plAlarm error: jrErrRef]);
        } @catch (JRErrException *je) {
#ifdef PESTER_TEST
            @throw;
#else
            if (![NSApp presentError: [[JRErrContext currentContext] popError]])
                continue;
#endif
        }
        if (alarm == nil)
            continue;
        [alarms addObject: alarm];
        [alarmsByUUID setObject: alarm forKey: [alarm uuid]];
        [alarm release];
    }
}

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    if ( (self = [super init]) != nil) {
        @try {
            NSArray *plPendingAlarms = [dict objectForRequiredKey: PLAlarmsPending];
            NSArray *plExpiredAlarms = [dict objectForRequiredKey: PLAlarmsExpired];
            NSUInteger alarmCount = [plPendingAlarms count] + [plExpiredAlarms count];

            alarmsByUUID = UUIDMapTableWithCapacity(alarmCount);
            alarms = [[NSMutableArray alloc] initWithCapacity: alarmCount];

            [self addAlarmsWithPropertyList: plPendingAlarms];

            // expired alarms may be ready for deletion, or may repeat - if the latter, PSAlarm will reschedule the alarm so the repeat interval begins at restoration time.
            [self addAlarmsWithPropertyList: plExpiredAlarms];
            expiredAlarms = [[NSMutableSet alloc] init];

            [self _setUpNotifications];
#ifdef PESTER_TEST
        } @catch (JRErrException *je) {
#endif
        } @catch (NSException *e) {
            NSString *description = [NSString stringWithFormat: NSLocalizedString(@"Sorry, Pester could not restore any alarm information at all. It is possible that your alarms are only readable by newer versions of Pester.\n\n%@", "PSAlarmsFailedToDeserializeError description"), [e description]];
            NSString *recoverySuggestion = NSLocalizedString(@"Click Start Over to erase all alarm information and continue.\n\nIf you accidentally opened an old version of Pester, click Quit.", "PSAlarmsFailedToDeserializeError recovery suggestion");

            NSArray *recoveryOptions = [NSArray arrayWithObjects: @"Quit", @"Start Over", nil];

            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      description,        NSLocalizedDescriptionKey,
                                      recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
                                      recoveryOptions,    NSLocalizedRecoveryOptionsErrorKey,
                                      self,               NSRecoveryAttempterErrorKey,
                                      nil];

            NSError *error = [NSError errorWithDomain: [[self class] description]
                                                 code: PSAlarmsFailedToDeserializeError
                                             userInfo: userInfo];

            JRPushErr((*jrErrRef = error, NO)); // XXX a better way?
            [self release];
            self = nil;
        }
    }
    returnJRErr(self);
}

#pragma mark archiving (Pester 1.0)

- (NSUInteger)countOfVersion1Alarms;
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

@implementation PSAlarms (NSErrorRecoveryAttempting)

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex;
{
    if (!JRErrEqual(error, [[self class] description], PSAlarmsFailedToDeserializeError))
        return NO;
    switch (recoveryOptionIndex) {
        case PSAlarmsFailedToDeserializeQuitRecoveryOptionIndex:
            exit(0);
        case PSAlarmsFailedToDeserializeStartOverRecoveryOptionIndex:
            return YES;
        default:
            NSAssert1(NO, @"Invalid recovery option index: %u", (unsigned)recoveryOptionIndex);
    }
    return NO;
}

@end