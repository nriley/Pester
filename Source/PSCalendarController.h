//
//  PSCalendarController.h
//  Pester
//
//  Created by Nicholas Riley on Fri Feb 14 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class OACalendarView;

@interface PSCalendarController : NSWindowController {
    IBOutlet OACalendarView *calendarView;
    IBOutlet NSButton *okButton;
    id delegate;
}

+ (PSCalendarController *)controllerWithDate:(NSCalendarDate *)aDate delegate:(id)aDelegate;

- (id)initWithDate:(NSCalendarDate *)aDate delegate:(id)aDelegate;

- (IBAction)close:(NSButton *)sender;
- (IBAction)cancel:(NSButton *)sender;
- (IBAction)today:(NSButton *)sender;

@end

@interface NSObject (PSCalendarControllerDelegate)

- (void)calendarController:(PSCalendarController *)controller didSetDate:(NSCalendarDate *)date;
- (NSView *)calendarControllerLaunchingView:(PSCalendarController *)controller;

@end