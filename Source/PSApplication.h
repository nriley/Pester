//
//  PSApplication.h
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PSAlarmsController;

@interface PSApplication : NSApplication {
    PSAlarmsController *alarmsController;
}

- (IBAction)orderFrontAlarmsPanel:(id)sender;

@end
