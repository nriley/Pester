//
//  PSAlarmsController.m
//  Pester
//
//  Created by Nicholas Riley on Fri Oct 11 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlarmsController.h"
#import "PSAlarm.h"
#import "NSTableView-NJRExtensions.h"


@implementation PSAlarmsController

- (id)init;
{
    if ( (self = [super initWithWindowNibName: @"Alarms"]) != nil) {
        alarms = [PSAlarms allAlarms];
        // XXX workaround for bug in 10.2.1, 10.1.5: autosave name set in IB doesn't show up
        [self setWindowFrameAutosaveName: @"Pester alarm list"];
        // Apple documents the NSUserDefaults key, so we can rely on it hopefully.
        if (nil == [[NSUserDefaults standardUserDefaults] objectForKey:
            [@"NSWindow Frame " stringByAppendingString: [[self window] frameAutosaveName]]])
        {
            [[self window] center];
        }
        [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(alarmsChanged) name: PSAlarmsDidChangeNotification object: alarms];
        [tableView setAutosaveName: @"Alarm list"];
        [tableView setAutosaveTableColumns: YES];
        [tableView noteNumberOfRowsChanged];
        [[self window] makeFirstResponder: tableView];
    }
    return self;
}

- (void)alarmsChanged; // XXX fix autoselection to be more reasonable, see whatever I did in that _Learning Cocoa_ project I think
{
    [tableView reloadData];
    [tableView deselectAll: self];
}

- (IBAction)remove:(id)sender;
{
    [alarms removeAlarmsAtIndices: [[tableView selectedRowEnumerator] allObjects]];
}

@end

@implementation PSAlarmsController (NSTableDataSource)

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [alarms alarmCount];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    PSAlarm *alarm = [alarms alarmAtIndex: row];

    if ([[tableColumn identifier] isEqualToString: @"message"]) return [alarm message];
    else {
        NSCalendarDate *date = [alarm date];
        if ([[tableColumn identifier] isEqualToString: @"date"]) return [alarm shortDateString];
        if ([[tableColumn identifier] isEqualToString: @"time"]) {
            if (date == nil) return @"ÇexpiredÈ";
            return [alarm timeString];
        }
    }
    return nil;
}
@end

@implementation PSAlarmsController (NSTableViewNotifications)

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
    [removeButton setEnabled: ([tableView numberOfSelectedRows] != 0)];
}

@end

@implementation PSAlarmsController (NSWindowDelegate)

// XXX workaround for bug in 10.1.5, 10.2.1 (and earlier?): no autosave on window move
- (void)windowDidMove:(NSNotification *)aNotification
{
    NSString *autosaveName = [[self window] frameAutosaveName];
    // on initial display, we get a notification inside -[NSWindow setFrameAutosaveName]!
    if (autosaveName != nil) {
        [[self window] saveFrameUsingName: autosaveName];
    }
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame;
{
    NSWindow *window = [tableView window];
    NSRect frame = [window frame];
    NSScrollView *scrollView = [tableView enclosingScrollView];
    float displayedHeight = [[scrollView contentView] bounds].size.height;
    float heightChange = [[scrollView documentView] bounds].size.height - displayedHeight;
    float heightExcess;

    if (heightChange >= 0 && heightChange <= 1) {
        // either the window is already optimal size, or it's too big
        float rowHeight = [tableView cellHeight];
        heightChange = (rowHeight * [tableView numberOfRows]) - displayedHeight;
    }

    frame.size.height += heightChange;

    if ( (heightExcess = [window minSize].height - frame.size.height) > 1 ||
         (heightExcess = [window maxSize].height - frame.size.height) < 1) {
        heightChange += heightExcess;
        frame.size.height += heightExcess;
    }

    frame.origin.y -= heightChange;

    return frame;
}

@end