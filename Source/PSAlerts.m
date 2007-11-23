//
//  PSAlerts.m
//  Pester
//
//  Created by Nicholas Riley on Sat Dec 21 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlerts.h"
#import "PSAlert.h"
#import "PSDockBounceAlert.h"
#import "PSNotifierAlert.h"
#import "PSBeepAlert.h"

// property list keys
static NSString * const PLAlerts = @"alerts"; // NSString

@implementation PSAlerts

#pragma mark initialize-release

- (id)init;
{
    if ( (self = [super init]) != nil) {
        alerts = [[NSMutableArray alloc] initWithCapacity: 4];
    }
    return self;
}

- (id)initWithPesterVersion1Alerts;
{
    if ( (self = [self init]) != nil) {
        [self addAlert: [PSDockBounceAlert alert]];
        [self addAlert: [PSNotifierAlert alert]];
        [self addAlert: [PSBeepAlert alertWithRepetitions: 1]];
    }
    return self;
}

- (void)dealloc;
{
    [alerts release]; alerts = nil;
    [super dealloc];
}

#pragma mark accessing

- (void)addAlert:(PSAlert *)alert;
{
    [alerts addObject: alert];
    if ([alert requiresPesterFrontmost])
        requirePesterFrontmost = YES;
}

- (void)removeAlerts;
{
    [alerts removeAllObjects];
    requirePesterFrontmost = NO;
}

- (NSEnumerator *)alertEnumerator;
{
    return [alerts objectEnumerator];
}

- (NSArray *)allAlerts;
{
    return [[alerts copy] autorelease];
}

- (BOOL)requirePesterFrontmost;
{
    return requirePesterFrontmost;
}

#pragma mark actions

- (void)prepareForAlarm:(PSAlarm *)alarm;
{
    [alerts makeObjectsPerformSelector: @selector(prepareForAlarm:) withObject: alarm];
}

- (void)triggerForAlarm:(PSAlarm *)alarm;
{
    [alerts makeObjectsPerformSelector: @selector(triggerForAlarm:) withObject: alarm];
}

#pragma mark printing

- (NSAttributedString *)prettyList;
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSEnumerator *e = [self alertEnumerator];
    PSAlert *alert;
    unsigned int length;
    while ( (alert = [e nextObject]) != nil) {
        [string appendAttributedString: [NSLocalizedString(@"* ", "Unordered list label (usually a bullet followed by a space)") small]];
        [string appendAttributedString: [alert actionDescription]];
        [string appendAttributedString: [@"\n" small]];
    }
    if ( (length = [string length]) == 0) {
        [string release];
        return nil;
    } else {
        NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [string deleteCharactersInRange: NSMakeRange(length - 1, 1)]; // remove trailing newline
        [paraStyle setHeadIndent: [[string attribute: NSFontAttributeName atIndex: 0 effectiveRange: NULL] widthOfString: NSLocalizedString(@"* ", "Unordered list label (usually a bullet followed by a space)")]];
        [string addAttribute: NSParagraphStyleAttributeName value: paraStyle range: NSMakeRange(0, length - 1)];
        [paraStyle release]; paraStyle = nil;
        return [string autorelease];
    }
}

#pragma mark property list serialization (Pester 1.1)

- (NSDictionary *)propertyListRepresentation;
{
    NSMutableArray *plAlerts = [[NSMutableArray alloc] initWithCapacity: [alerts count]];
    NSEnumerator *e = [self alertEnumerator];
    PSAlert *alert;
    while ( (alert = [e nextObject]) != nil) {
        [plAlerts addObject: [alert propertyListRepresentation]];
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObject: plAlerts forKey: PLAlerts];
    [plAlerts release];
    return dict;
}

- (id)initWithPropertyList:(NSDictionary *)dict;
{
    if ( (self = [self init]) != nil) {
        NSArray *plAlerts = [dict objectForKey: PLAlerts];
        NSEnumerator *e = [plAlerts objectEnumerator];
        NSDictionary *alertDict;
        while ( (alertDict = [e nextObject]) != nil) {
            [self addAlert: [[PSAlert alloc] initWithPropertyList: alertDict]];
        }
    }
    return self;
}

@end
