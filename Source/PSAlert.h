//
//  PSAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSAlarm.h"

@interface PSAlert : NSObject {

}

// XXX need archiving support

// subclasses should implement these methods
+ (PSAlert *)alert;
- (void)triggerForAlarm:(PSAlarm *)alarm;

@end
