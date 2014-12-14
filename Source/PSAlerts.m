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

PSAlerts * __attribute__((overloadable))
JRErrExpressionAdapter(PSAlerts *(^block)(void), JRErrExpression *expression, NSError **jrErrRef) {
    *jrErrRef = nil;
    PSAlerts *result = block();
    if (*jrErrRef != nil)
        JRErrReportError(expression, *jrErrRef, nil);
    return result;
}

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
    NSString *listLabel = NSLocalizedString(@"* ", "Unordered list label (usually a bullet followed by a space)");
    unsigned int length;
    while ( (alert = [e nextObject]) != nil) {
        [string appendAttributedString: [listLabel small]];
        [string appendAttributedString: [alert actionDescription]];
        [string appendAttributedString: [@"\n" small]];
    }
    if ( (length = [string length]) == 0) {
        [string release];
        return nil;
    } else {
        NSMutableParagraphStyle *paraStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [string deleteCharactersInRange: NSMakeRange(length - 1, 1)]; // remove trailing newline
        [paraStyle setHeadIndent: [listLabel sizeWithAttributes: [string attributesAtIndex: 0 effectiveRange: NULL]].width];
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

- (instancetype)initWithPropertyList:(NSDictionary *)dict error:(NSError **)error;
{
    if ( (self = [self init]) != nil) {
	@try {
            NSMutableArray *exceptions = nil;

            for (NSDictionary *alertDict in [dict objectForKey: PLAlerts]) {
                @try {
                    PSAlert *alert = JRThrowErr([[PSAlert alloc] initWithPropertyList: alertDict error: jrErrRef]);
                    [self addAlert: alert];
                } @catch (NSException *e) {
                    if (exceptions == nil)
                        exceptions = [NSMutableArray array];
                    [exceptions addObject: e];
                }
            }

            if (exceptions != nil)
                JRThrowErrMsg([[exceptions valueForKey: @"description"] componentsJoinedByString: @"\n"], nil);
	} @catch (JRErrException *je) {
            // object may be partially valid; keep it around
        } @catch (NSException *e) {
	    [self release];
	    @throw;
	}
    }
    returnJRErr(self, self);
}

@end
