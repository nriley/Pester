//
//  PSGrowlController.h
//  Pester
//
//  Created by Nicholas Riley on 8/24/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface PSGrowlController : NSObject <GrowlApplicationBridgeDelegate> {
    NSMutableDictionary *outstandingNotifications;
}

+ (PSGrowlController *)sharedController;

- (void)notifyWithTitle:(NSString *)title
	    description:(NSString *)description
       notificationName:(NSString *)notificationName
	       isSticky:(BOOL)isSticky
		 target:(id)target
	       selector:(SEL)selector
		 object:(id)object
	    onlyOnClick:(BOOL)onlyOnClick;

- (void)timeOutAllNotifications;

@end
