//
//  PSPreferencesController.h
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class NJRHotKeyField;

@interface PSPreferencesController : NSWindowController {
    IBOutlet NJRHotKeyField *setAlarmHotKey;
}

@end
