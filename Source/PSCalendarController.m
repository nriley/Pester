//
//  PSCalendarController.m
//  Pester
//
//  Created by Nicholas Riley on Fri Feb 14 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSCalendarController.h"
#import "OACalendarView.h"
#import "NSCalendarDate-OFExtensions.h"
#import "NSCalendarDate-NJRExtensions.h"

@implementation PSCalendarController

+ (PSCalendarController *)controllerWithDate:(NSCalendarDate *)aDate delegate:(id)aDelegate;
{
    return [[self alloc] initWithDate:(NSCalendarDate *)aDate delegate:(id)aDelegate];
}

- (id)initWithDate:(NSCalendarDate *)aDate delegate:(id)aDelegate;
{
    if ([self initWithWindowNibName: @"Calendar"]) {
        NSWindow *window = [self window]; // connect outlets
        [calendarView setTarget: self]; // delegate
        [calendarView setSelectionType: OACalendarViewSelectByDay];
        [calendarView setShowsDaysForOtherMonths: YES];
        if (aDate == nil) aDate = [NSCalendarDate calendarDate];
        [calendarView setSelectedDay: aDate];
        [calendarView setVisibleMonth: aDate];
        delegate = [aDelegate retain];

        NSView *view = [aDelegate calendarControllerLaunchingView: self];
        if (view != nil) {
            NSRect rect = [view convertRect: [view bounds] toView: nil];
            NSWindow *parentWindow = [view window];
            rect.origin = [parentWindow convertBaseToScreen: rect.origin];
            rect.origin.x -= [window frame].size.width - rect.size.width;
            [window setFrameTopLeftPoint: rect.origin];
            NSRect visibleFrame = [[parentWindow screen] visibleFrame];
            if (!NSContainsRect(visibleFrame, [window frame])) {
                NSPoint textFieldTopLeft = { rect.origin.x, rect.origin.y + rect.size.height };
                [window setFrameOrigin: textFieldTopLeft];
            }
        }
        [window setOpaque: NO];
        [window setBackgroundColor: [NSColor colorWithCalibratedWhite: 0.81f alpha: 0.9f]];
        [window setHasShadow: NO];
        [window setLevel: NSModalPanelWindowLevel];
        [NSApp runModalForWindow: window];
    }
    return self;
}

- (void)dealloc;
{
    [delegate release];
    [super dealloc];
}

- (IBAction)close:(NSButton *)sender;
{
    [NSApp stopModal];
    [delegate calendarController: self didSetDate: [calendarView selectedDay]];
    [self close];
}

- (IBAction)cancel:(NSButton *)sender;
{
    [NSApp stopModal];
    [self close];
}

- (IBAction)today:(NSButton *)sender;
{
    NSCalendarDate *today = [NSCalendarDate calendarDate];
    [calendarView setSelectedDay: today];
    [calendarView setVisibleMonth: today];
}

@end

@implementation PSCalendarController (OACalendarViewDelegate)

- (BOOL)calendarView:(OACalendarView *)aCalendarView shouldSelectDate:(NSCalendarDate *)aDate;
{
    return ([[NSCalendarDate dateForDay: aDate] compare: [NSCalendarDate dateForDay: [NSCalendarDate calendarDate]]] != NSOrderedAscending);
}

- (int)calendarView:(OACalendarView *)aCalendarView highlightMaskForVisibleMonth:(NSCalendarDate *)visibleMonth;
{
    NSCalendarDate *today = [NSCalendarDate calendarDate];
    if ([visibleMonth yearOfCommonEra] == [today yearOfCommonEra] && [visibleMonth monthOfYear] == [today monthOfYear]) {
        return 1 << ([today dayOfMonth] - 1 + [[today firstDayOfMonth] dayOfWeek]);
    }

    return 0;
}

- (void)calendarViewShouldDismiss:(OACalendarView *)aCalendarView;
{
    [okButton performClick: aCalendarView];
}

@end

@implementation PSCalendarController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    [self autorelease];
}

@end