//
//  PSPreferencesController.m
//  Pester
//
//  Created by Nicholas Riley on Sat Mar 29 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSPreferencesController.h"
#import "NJRHotKeyField.h"

@implementation PSPreferencesController

#pragma mark interface updating

- (void)update;
{
    // XXX do what we do in HL, stop more than one prefs window from appearing
}

#pragma mark preferences I/O

- (void)readFromPrefs;
{
    // XXX
}

- (void)writeToPrefs;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // XXX
    [defaults synchronize];
}

#pragma mark initialize-release

- (id)init {
    if ( (self = [super initWithWindowNibName: @"Preferences"]) != nil) {
        [self window]; // connect outlets
        [self readFromPrefs];
        [self update];
    }
    return self;
}

- (void)dealloc;
{

}

@end
