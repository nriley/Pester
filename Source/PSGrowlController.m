//
//  PSGrowlController.m
//  Pester
//
//  Created by Nicholas Riley on 8/24/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "PSGrowlController.h"

static PSGrowlController *PSGrowlControllerShared;

@implementation PSGrowlController

#pragma mark initialize-release

+ (PSGrowlController *)sharedController;
{
    if (PSGrowlControllerShared == nil) {
        PSGrowlControllerShared = [[PSGrowlController alloc] init];

	[GrowlApplicationBridge registerWithDictionary:
	 [NSDictionary dictionaryWithContentsOfFile:
	  [[NSBundle mainBundle] pathForResource: @"Growl Registration Ticket"
					  ofType: GROWL_REG_DICT_EXTENSION]]];
	[GrowlApplicationBridge setGrowlDelegate: PSGrowlControllerShared];
    }
    
    return PSGrowlControllerShared;
}

- (id)init;
{
    if ( (self = [super init]) != nil)
	outstandingNotifications = [[NSMutableDictionary alloc] init];
    
    return self;
}


#pragma mark actions

- (void)notifyWithTitle:(NSString *)title
	    description:(NSString *)description
       notificationName:(NSString *)notificationName
	       isSticky:(BOOL)isSticky
		 target:(id)target
	       selector:(SEL)selector
		 object:(id)object
	    onlyOnClick:(BOOL)onlyOnClick;
{
    if (![GrowlApplicationBridge isGrowlRunning])
	goto notificationFailed;
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:
				[target methodSignatureForSelector: selector]];
    [invocation setTarget: target];
    [invocation setSelector: selector];
    [invocation setArgument: &object atIndex: 2];
    [invocation retainArguments];
    
    // XXX alarms should have UUIDs instead, or in addition
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid == NULL)
	goto notificationFailed;
    
    NSString *uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    if (uuidString == nil)
	goto notificationFailed;
	
    NSDictionary *notificationInfo =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 invocation, @"invocation",
	 [NSNumber numberWithBool: onlyOnClick], @"onlyOnClick",
	 nil];
    
    [outstandingNotifications setObject: notificationInfo
				 forKey: uuidString];
     
    [GrowlApplicationBridge notifyWithTitle: title
				description: description
			   notificationName: notificationName
				   iconData: nil
				   priority: 0
				   isSticky: isSticky
			       clickContext: (NSString *)uuidString];
    return;

notificationFailed:
    if (!onlyOnClick)
	[target performSelector: selector withObject: object];
}

- (void)timeOutAllNotifications;
{
    NSEnumerator *e = [[outstandingNotifications allKeys] objectEnumerator];
    NSString *uuidString;
    while ( (uuidString = [e nextObject]) != nil) {
        NSDictionary *notificationInfo = [outstandingNotifications objectForKey: uuidString];

        if ([[notificationInfo objectForKey: @"onlyOnClick"] boolValue])
            continue;
        [[notificationInfo objectForKey: @"invocation"] invoke];
        [outstandingNotifications removeObjectForKey: uuidString];
    }
}

@end

@implementation PSGrowlController (GrowlApplicationBridgeDelegate_InformalProtocol)

- (void)growlNotificationWasClicked:(id)clickContext;
{
    NSDictionary *notificationInfo = [outstandingNotifications objectForKey: clickContext];
    if (notificationInfo == nil)
	return;
    
    [[notificationInfo objectForKey: @"invocation"] invoke];
    
    [outstandingNotifications removeObjectForKey: clickContext];
}

- (void)growlNotificationTimedOut:(id)clickContext;
{
    NSDictionary *notificationInfo = [outstandingNotifications objectForKey: clickContext];
    if (notificationInfo == nil)
	return;
    
    if (![[notificationInfo objectForKey: @"onlyOnClick"] boolValue])
	[[notificationInfo objectForKey: @"invocation"] invoke];
    
    [outstandingNotifications removeObjectForKey: clickContext];
}

@end
