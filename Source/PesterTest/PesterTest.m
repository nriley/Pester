//
//  PesterTest.m
//  PesterTest
//
//  Created by Nicholas Riley on 8/16/13.
//
//

#import "PesterTest.h"

#import "PSAlarms.h"
#import "PSAlerts.h"

@implementation PesterTest

- (void)setUp;
{
    [super setUp];
    
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    fixtures = [[NSDictionary alloc] initWithContentsOfURL:[testBundle URLForResource:@"PesterTestFixtures" withExtension:@"plist"]];
    NSAssert(fixtures != nil, @"PesterTestFixtures.plist could not be loaded; check syntax");
}

- (void)tearDown;
{
    [fixtures release];
    fixtures = nil;
    
    [super tearDown];
}

- (id)fixture:(NSString *)key;
{
    id fixture = [fixtures objectForKey:key];
    NSAssert1(fixture != nil, @"Could not load test fixture %@", key);

    return fixture;
}

#define AssertPlistEqual(_original, _reconstructed) \
    XCTAssertNotNil(_reconstructed); \
    XCTAssertEqualObjects([_original description], [[_reconstructed propertyListRepresentation] description]);

- (void)testAlarmRestoration;
{
    NSError *error = nil;
    PSAlarms *alarms;

    NSDictionary *plAlarmsEmpty = [self fixture:@"alarmsEmpty"];
    NSDictionary *plValidAlarm = [self fixture:@"alarmValid"];

    NSMutableDictionary *plAlarms, *plAlarm;

    // no alarms
    alarms = [[PSAlarms alloc] initWithPropertyList:plAlarmsEmpty error:&error];
    XCTAssertNil(error);
    AssertPlistEqual(plAlarmsEmpty, alarms);
    [alarms release];

    // one valid alarm
    plAlarms = [plAlarmsEmpty mutableCopy];
    [plAlarms setObject: @[plValidAlarm] forKey:@"pending"];
    alarms = [[PSAlarms alloc] initWithPropertyList:plAlarms error:&error];
    XCTAssertNil(error);
    AssertPlistEqual(plAlarms, alarms);
    [alarms release];
    [plAlarms release];

    // alarm with one valid, one invalid alert
    plAlarms = [plAlarmsEmpty mutableCopy];
    plAlarm = [plValidAlarm mutableCopy];
    [plAlarm setObject:[self fixture:@"alertsOneValidOneInvalid"] forKey:@"alerts"];
    [plAlarms setObject: @[plAlarm] forKey:@"pending"];
    alarms = [[PSAlarms alloc] initWithPropertyList:plAlarms error:&error];
    XCTAssertNil(alarms); // no recovery when testing, but test for correct # of recovery options
    XCTAssertEqual([[[error userInfo] objectForKey:NSLocalizedRecoveryOptionsErrorKey] count], 4U);
    [alarms release];
    [plAlarm release];
    [plAlarms release];

    // alarm with two invalid alerts
    plAlarms = [plAlarmsEmpty mutableCopy];
    plAlarm = [plValidAlarm mutableCopy];
    [plAlarm setObject:[self fixture:@"alertsTwoInvalid"] forKey:@"alerts"];
    [plAlarms setObject: @[plAlarm] forKey:@"pending"];
    alarms = [[PSAlarms alloc] initWithPropertyList:plAlarms error:&error];
    XCTAssertNil(alarms); // no recovery when testing, but test for correct # of recovery options
    XCTAssertEqual([[[error userInfo] objectForKey:NSLocalizedRecoveryOptionsErrorKey] count], 3U);
    [alarms release];
    [plAlarm release];
    [plAlarms release];
}

- (void)testAlertRestoration;
{
    NSError *error = nil;
    PSAlerts *alerts;

    NSDictionary *plAlerts;

    // two valid alerts
    plAlerts = [self fixture:@"alertsTwoValid"];
    alerts = [[PSAlerts alloc] initWithPropertyList:plAlerts error:&error];
    XCTAssertNil(error);
    AssertPlistEqual(plAlerts, alerts);
    [alerts release];

    // one valid, one invalid alert
    plAlerts = [self fixture:@"alertsOneValidOneInvalid"];
    alerts = [[PSAlerts alloc] initWithPropertyList:plAlerts error:&error];
    XCTAssertEqualObjects([error localizedDescription], @"Alert class PSBogusAlert is not available");
    AssertPlistEqual([self fixture:@"alertsOneValid"], alerts);
    [alerts release];

    // two invalid alerts
    plAlerts = [self fixture:@"alertsTwoInvalid"];
    alerts = [[PSAlerts alloc] initWithPropertyList:plAlerts error:&error];
    XCTAssertEqualObjects([error localizedDescription], @"Alert class PSBogusAlert is not available\nAlert class PSInvalidAlert is not available");
    AssertPlistEqual([self fixture:@"alertsEmpty"], alerts);
    [alerts release];
}

@end
