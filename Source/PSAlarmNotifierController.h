//
//  PSAlarmNotifierController.h
//  Pester
//
//  Created by Nicholas Riley on Tue Oct 08 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface PSAlarmNotifierController : NSWindowController {
    IBOutlet NSTextField *messageField;
    IBOutlet NSTextField *dateField;
}

- (IBAction)close:(NSButton *)sender;

@end
