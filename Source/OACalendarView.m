// Copyright 2001-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.

#import "OACalendarView.h"
#import "NSImage-OAExtensions.h"
#import "NSCalendarDate-OFExtensions.h"

#import <AppKit/AppKit.h>

// RCS_ID("$Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniAppKit/Widgets.subproj/OACalendarView.m,v 1.20 2002/12/07 00:23:40 andrew Exp $")


/*
    Some Notes:
    
    - Setting the View Size: see the notes in -initWithFrame: for some guidelines for determining what size you will want to give this view. Those notes also give information about font sizes and how they affect us and the size calculations. If you set the view size to a non-optimal size, we won't use all the space.
    
    - Dynamically Adjusting the Cell Display: check out the "delegate" method -calendarView:willDisplayCell:forDate: in order to adjust the cell attributes (such as the font color, etc.). Note that if you make any changes which impact the cell size, the calendar is unlikely to draw as desired, so this is mostly useful for color changes. You can also use -calendarView:highlightMaskForVisibleMonth: to get highlighting of certain days. This is more efficient since we need only ask once for the month rather than once for each cell, but it is far less flexible, and currently doesn't allow control over the highlight color used. Also, don't bother to implement both methods: only the former will be used if it is available.
    
    - We should have a real delegate instead of treating the target as the delgate.
    
    - We could benefit from some more configurability: specify whether or not to draw vertical/horizontal grid lines, grid and border widths, fonts, whether or not to display the top control area, whether or not the user can change the displayed month/year independant of whether they can change the selected date, etc.
    
    - We could be more efficient, such as in only calculating things we need. The biggest problem (probably) is that we recalculate everything on every -drawRect:, simply because I didn't see an ideal place to know when we've resized. (With the current implementation, the monthAndYearRect would also need to be recalculated any time the month or year changes, so that the month and year will be correctly centered.)
*/


@interface OACalendarView (Private)

- (NSButton *)_createButtonWithFrame:(NSRect)buttonFrame;

- (void)_calculateSizes;
- (void)_drawDaysOfMonthInRect:(NSRect)rect;
- (void)_drawGridInRect:(NSRect)rect;

- (float)_maximumDayOfWeekWidth;
- (NSSize)_maximumDayOfMonthSize;
- (float)_minimumColumnWidth;
- (float)_minimumRowHeight;

- (NSCalendarDate *)_hitDateWithLocation:(NSPoint)targetPoint;
- (NSCalendarDate *)_hitWeekdayWithLocation:(NSPoint)targetPoint;

@end

@interface OACalendarView (PrivateActions)

- (IBAction)previous:(id)sender;
- (IBAction)next:(id)sender;

@end

@implementation OACalendarView

const float OACalendarViewButtonWidth = 15.0f;
const float OACalendarViewButtonHeight = 15.0f;
const float OACalendarViewSpaceBetweenMonthYearAndGrid = 6.0f;
const int OACalendarViewNumDaysPerWeek = 7;
const int OACalendarViewMaxNumWeeksIntersectedByMonth = 6;

//
// Init / dealloc
//

- (id)initWithFrame:(NSRect)frameRect;
{
    // The calendar will only resize on certain boundaries. "Ideal" sizes are: 
    //     - width = (multiple of 7) + 1, where multiple >= 22; "minimum" width is 162
    //     - height = (multiple of 6) + 39, where multiple >= 15; "minimum" height is 129
    
    // In reality you can shrink it smaller than the minimums given here, and it tends to look ok for a bit, but this is the "optimum" minimum. But you will want to set your size based on the guidelines above, or the calendar will not actually fill the view exactly.

    // The "minimum" view size comes out to be 162w x 129h. (Where minimum.width = 23 [minimum column width] * 7 [num days per week] + 1.0 [for the side border], and minimum.height = 22 [month/year control area height; includes the space between control area and grid] + 17 [the  grid header height] + (15 [minimum row height] * 6 [max num weeks in month]). [Don't need to allow 1 for the bottom border due to the fact that there's no top border per se.]) (We used to say that the minimum height was 155w x 123h, but that was wrong - we weren't including the grid lines in the row/column sizes.)
    // These sizes will need to be adjusted if the font changes, grid or border widths change, etc. We use the controlContentFontOfSize:11.0 for the  - if the control content font is changed our calculations will change and the above sizes will be incorrect. Similarly, we use the default NSTextFieldCell font/size for the month/year header, and the default NSTableHeaderCell font/size for the day of week headers; if either of those change, the aove sizes will be incorrect.

    NSDateFormatter *monthAndYearFormatter;
    int index;
    NSUserDefaults *defaults;
    NSArray *shortWeekDays;
    NSRect buttonFrame;
    NSButton *button;
    NSBundle *thisBundle;

    if ([super initWithFrame:frameRect] == nil)
        return nil;
    
    thisBundle = [NSBundle bundleForClass: [OACalendarView class]];
    monthAndYearTextFieldCell = [[NSTextFieldCell alloc] init];
    monthAndYearFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%B %Y" allowNaturalLanguage:NO];
    [monthAndYearTextFieldCell setFormatter:monthAndYearFormatter];
    [monthAndYearTextFieldCell setFont: [NSFont boldSystemFontOfSize: [NSFont systemFontSize]]];
    [monthAndYearFormatter release];

    defaults = [NSUserDefaults standardUserDefaults];
    shortWeekDays = [defaults objectForKey:NSShortWeekDayNameArray];
    for (index = 0; index < OACalendarViewNumDaysPerWeek; index++) {
        dayOfWeekCell[index] = [[NSTableHeaderCell alloc] init];
        [dayOfWeekCell[index] setAlignment:NSCenterTextAlignment];
        [dayOfWeekCell[index] setStringValue:[[shortWeekDays objectAtIndex:index] substringToIndex:1]];
    }

    dayOfMonthCell = [[NSTextFieldCell alloc] init];
    [dayOfMonthCell setAlignment:NSCenterTextAlignment];
    [dayOfMonthCell setFont:[NSFont controlContentFontOfSize:11.0f]];

    buttons = [[NSMutableArray alloc] initWithCapacity:2];

    monthAndYearView = [[NSView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, frameRect.size.width, OACalendarViewButtonHeight + 2)];
    [monthAndYearView setAutoresizingMask:NSViewWidthSizable];

    // Add left/right buttons

    buttonFrame = NSMakeRect(0.0f, 0.0f, OACalendarViewButtonWidth, OACalendarViewButtonHeight);
    button = [self _createButtonWithFrame:buttonFrame];
    [button setImage:[NSImage imageNamed:@"OALeftArrow" inBundle:thisBundle]];
    [button setAlternateImage:[NSImage imageNamed:@"OALeftArrowPressed" inBundle:thisBundle]];
    [button setAction:@selector(previous:)];
    [button setAutoresizingMask:NSViewMaxXMargin];
    [monthAndYearView addSubview:button];

    buttonFrame = NSMakeRect(frameRect.size.width - OACalendarViewButtonWidth, 0.0f, OACalendarViewButtonWidth, OACalendarViewButtonHeight);
    button = [self _createButtonWithFrame:buttonFrame];
    [button setImage:[NSImage imageNamed:@"OARightArrow" inBundle:thisBundle]];
    [button setAlternateImage:[NSImage imageNamed:@"OARightArrowPressed" inBundle:thisBundle]];
    [button setAction:@selector(next:)];
    [button setAutoresizingMask:NSViewMinXMargin];
    [monthAndYearView addSubview:button];

    [self addSubview:monthAndYearView];
    [monthAndYearView release];

//[self sizeToFit];
//NSLog(@"frame: %@", NSStringFromRect([self frame]));

    [self setVisibleMonth:[NSCalendarDate calendarDate]];
    [self setSelectedDay:[NSCalendarDate calendarDate]];
    
    return self;
}

- (void)dealloc;
{
    int index;

    [dayOfMonthCell release];

    for (index = 0; index < OACalendarViewNumDaysPerWeek; index++)
        [dayOfWeekCell[index] release];

    [monthAndYearTextFieldCell release];
    [buttons release];
    [selectedDay release];
    [visibleMonth release];

    [super dealloc];
}


//
// NSControl overrides
//

+ (Class)cellClass;
{
    // We need to have an NSActionCell (or subclass of that) to handle the target and action; otherwise, you just can't set those values.
    return [NSActionCell class];
}

- (BOOL)mouseDownCanMoveWindow;
{
    return YES;
}

- (void)setEnabled:(BOOL)flag;
{
    unsigned int buttonIndex;

    [super setEnabled:flag];
    
    buttonIndex = [buttons count];
    while (buttonIndex--)
        [[buttons objectAtIndex:buttonIndex] setEnabled:flag];
}

- (void)sizeToFit;
{
    NSSize minimumSize;

    // we need calculateSizes in order to get the monthAndYearRect; would be better to restructure some of that
    // it would be good to refactor the size calculation (or pass it some parameters) so that we could merely calculate the stuff we need (or have _calculateSizes do all our work, based on the parameters we provide)
    [self _calculateSizes];

    minimumSize.height = monthAndYearRect.size.height + gridHeaderRect.size.height + ((OACalendarViewMaxNumWeeksIntersectedByMonth * [self _minimumRowHeight]));
    // This should really check the lengths of the months, and include space for the buttons.
    minimumSize.width = ([self _minimumColumnWidth] * OACalendarViewNumDaysPerWeek) + 1.0f;

    [self setFrameSize:minimumSize];
    [self setNeedsDisplay:YES];
}


//
// NSView overrides
//

- (BOOL)needsPanelToBecomeKey;
{
    return YES;
}

- (BOOL)isFlipped;
{
    return YES;
}

- (void)drawRect:(NSRect)rect;
{
    int columnIndex;
    NSRect tempRect;
    
    [self _calculateSizes];
    
// for testing, to see if there's anything we're not covering
//[[NSColor greenColor] set];
//NSRectFill(gridHeaderAndBodyRect);
// or...
//NSRectFill([self bounds]);
    
    // draw the month/year
    [monthAndYearTextFieldCell drawWithFrame:monthAndYearRect inView:self];
    
    // draw the grid header
    tempRect = gridHeaderRect;
    tempRect.size.width = columnWidth;
    for (columnIndex = 0; columnIndex < OACalendarViewNumDaysPerWeek; columnIndex++) {
        [dayOfWeekCell[columnIndex] drawWithFrame:tempRect inView:self];
        tempRect.origin.x += columnWidth;
    }

    // draw the grid background
    [[NSColor controlBackgroundColor] set];
    NSRectFill(gridBodyRect);

    // fill in the grid
    [self _drawGridInRect:gridBodyRect];
    [self _drawDaysOfMonthInRect:gridBodyRect];
    
    // draw a border around the whole thing. This ends up drawing over the top and right side borders of the header, but that's ok because we don't want their border, we want ours. Also, it ends up covering any overdraw from selected sundays and saturdays, since the selected day covers the bordering area where vertical grid lines would be (an aesthetic decision because we don't draw vertical grid lines, another aesthetic decision).
    [[NSColor gridColor] set];
    NSFrameRect(gridHeaderAndBodyRect);

}

- (void)mouseDown:(NSEvent *)mouseEvent;
{
    if ([self isEnabled]) {
        NSCalendarDate *hitDate;
        NSPoint location;
    
        location = [self convertPoint:[mouseEvent locationInWindow] fromView:nil];
        hitDate = [self _hitDateWithLocation:location];
        if (hitDate) {
            id target = [self target];
            if (!flags.targetApprovesDateSelection || [target calendarView:self shouldSelectDate:hitDate]) {
                [self setSelectedDay:hitDate];
                [self setVisibleMonth:hitDate];
                if (flags.targetReceivesDismiss && [mouseEvent clickCount] == 2)
                    [target calendarViewShouldDismiss: target];
                [self sendAction:[self action] to:target];
            }
            
        } else if (selectionType == OACalendarViewSelectByWeekday) {
            NSCalendarDate *hitWeekday;
            
            hitWeekday = [self _hitWeekdayWithLocation:location];
            if (hitWeekday) {
                id target = [self target];
                if (!flags.targetApprovesDateSelection || [target calendarView:self shouldSelectDate:hitWeekday]) {
                    [self setSelectedDay:hitWeekday];
                    [self sendAction:[self action] to: target];
                    if (flags.targetReceivesDismiss && [mouseEvent clickCount] == 2)
                        [target calendarViewShouldDismiss: target];
                }
            }
        }
    }
}


//
// API
//

- (NSCalendarDate *)visibleMonth;
{
    return visibleMonth;
}

- (void)setVisibleMonth:(NSCalendarDate *)aDate;
{
    [visibleMonth release];
    visibleMonth = [[aDate firstDayOfMonth] retain];
    [monthAndYearTextFieldCell setObjectValue:visibleMonth];

    [self updateHighlightMask];
    [self setNeedsDisplay:YES];
    
    if (flags.targetWatchesVisibleMonth)
        [[self target] calendarView:self didChangeVisibleMonth:visibleMonth];
}

- (NSCalendarDate *)selectedDay;
{
    return selectedDay;
}

- (void)setSelectedDay:(NSCalendarDate *)newSelectedDay;
{
    if (newSelectedDay == selectedDay || [newSelectedDay isEqual:selectedDay])
        return;
    
    [selectedDay release];
    selectedDay = [newSelectedDay retain];
    [self setNeedsDisplay:YES];
}

- (int)dayHighlightMask;
{
    return dayHighlightMask;
}

- (void)setDayHighlightMask:(int)newMask;
{
    dayHighlightMask = newMask;
    [self setNeedsDisplay:YES];
}

- (void)updateHighlightMask;
{
    if (flags.targetProvidesHighlightMask) {
        int mask;
        mask = [[self target] calendarView:self highlightMaskForVisibleMonth:visibleMonth];
        [self setDayHighlightMask:mask];
    } else
        [self setDayHighlightMask:0];

    [self setNeedsDisplay:YES];
}

- (BOOL)showsDaysForOtherMonths;
{
    return flags.showsDaysForOtherMonths;
}

- (void)setShowsDaysForOtherMonths:(BOOL)value;
{
    if (value != flags.showsDaysForOtherMonths) {
        flags.showsDaysForOtherMonths = value;

        [self setNeedsDisplay:YES];
    }
}

- (OACalendarViewSelectionType)selectionType;
{
    return selectionType;
}

- (void)setSelectionType:(OACalendarViewSelectionType)value;
{
    NSParameterAssert((value == OACalendarViewSelectByDay) || (value == OACalendarViewSelectByWeek) || (value == OACalendarViewSelectByWeekday));
    if (selectionType != value) {
        selectionType = value;

        [self setNeedsDisplay:YES];
    }
}

- (NSArray *)selectedDays;
{
    if (!selectedDay)
        return nil;

    switch (selectionType) {
        case OACalendarViewSelectByDay:
            return [NSArray arrayWithObject:selectedDay];
            break;
            
        case OACalendarViewSelectByWeek:
            {
                NSMutableArray *days;
                NSCalendarDate *day;
                int index;
                
                days = [NSMutableArray arrayWithCapacity:OACalendarViewNumDaysPerWeek];
                day = [selectedDay dateByAddingYears:0 months:0 days:-[selectedDay dayOfWeek] hours:0 minutes:0 seconds:0];
                for (index = 0; index < OACalendarViewNumDaysPerWeek; index++) {
                    NSCalendarDate *nextDay;

                    nextDay = [day dateByAddingYears:0 months:0 days:index hours:0 minutes:0 seconds:0];
                    if (flags.showsDaysForOtherMonths || [nextDay monthOfYear] == [selectedDay monthOfYear])
                        [days addObject:nextDay];                    
                }
            
                return days;
            }            
            break;

        case OACalendarViewSelectByWeekday:
            {
                NSMutableArray *days;
                NSCalendarDate *day;
                int index;
                
                days = [NSMutableArray arrayWithCapacity:OACalendarViewMaxNumWeeksIntersectedByMonth];
                day = [selectedDay dateByAddingYears:0 months:0 days:-(([selectedDay weekOfMonth] - 1) * OACalendarViewNumDaysPerWeek) hours:0 minutes:0 seconds:0];
                for (index = 0; index < OACalendarViewMaxNumWeeksIntersectedByMonth; index++) {
                    NSCalendarDate *nextDay;

                    nextDay = [day dateByAddingYears:0 months:0 days:(index * OACalendarViewNumDaysPerWeek) hours:0 minutes:0 seconds:0];
                    if (flags.showsDaysForOtherMonths || [nextDay monthOfYear] == [selectedDay monthOfYear])
                        [days addObject:nextDay];
                }

                return days;
            }
            break;
            
        default:
            [NSException raise:NSInvalidArgumentException format:@"OACalendarView: Unknown selection type: %d", selectionType];
            return nil;
            break;
    }
}


//
// Actions
//

- (IBAction)previous:(id)sender;
{
    if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
        [self previousYear: sender];
    else
        [self previousMonth: sender];
}

- (IBAction)next:(id)sender;
{
    if ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
        [self nextYear: sender];
    else
        [self nextMonth: sender];
}

- (IBAction)previousMonth:(id)sender;
{
    NSCalendarDate *newDate;

    newDate = [visibleMonth dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
    [self setVisibleMonth:newDate];
}

- (IBAction)nextMonth:(id)sender;
{
    NSCalendarDate *newDate;

    newDate = [visibleMonth dateByAddingYears:0 months:1 days:0 hours:0 minutes:0 seconds:0];
    [self setVisibleMonth:newDate];
}

- (IBAction)previousYear:(id)sender;
{
    NSCalendarDate *newDate;

    newDate = [visibleMonth dateByAddingYears:-1 months:0 days:0 hours:0 minutes:0 seconds:0];
    [self setVisibleMonth:newDate];
}

- (IBAction)nextYear:(id)sender;
{
    NSCalendarDate *newDate;

    newDate = [visibleMonth dateByAddingYears:1 months:0 days:0 hours:0 minutes:0 seconds:0];
    [self setVisibleMonth:newDate];
}

- (void)keyDown:(NSEvent *)theEvent;
{
    BOOL commandKey = ([theEvent modifierFlags] & NSCommandKeyMask) != 0;
    BOOL optionKey = ([theEvent modifierFlags] & NSAlternateKeyMask) != 0;
    NSCalendarDate *newDate = nil;
    unichar firstCharacter = [[theEvent characters] characterAtIndex: 0];
    // move by week, or month/year if modified
    if (firstCharacter == NSUpArrowFunctionKey) {
        if (commandKey) firstCharacter = NSLeftArrowFunctionKey;
        else newDate = [selectedDay dateByAddingYears:0 months:0 days:-7 hours:0 minutes:0 seconds:0];
    } else if (firstCharacter == NSDownArrowFunctionKey) {
        if (commandKey) firstCharacter = NSRightArrowFunctionKey;
        else newDate = [selectedDay dateByAddingYears:0 months:0 days:7 hours:0 minutes:0 seconds:0];
    }
    // move by day, or month/year if modified
    if (firstCharacter == NSLeftArrowFunctionKey) {
        if (commandKey) {
            if (optionKey)
                newDate = [selectedDay dateByAddingYears:-1 months:0 days:0 hours:0 minutes:0 seconds:0];
            else
                newDate = [selectedDay dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
        } else newDate = [selectedDay dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
    } else if (firstCharacter == NSRightArrowFunctionKey) {
        if (commandKey) {
            if (optionKey)
                newDate = [selectedDay dateByAddingYears:1 months:0 days:0 hours:0 minutes:0 seconds:0];
            else
                newDate = [selectedDay dateByAddingYears:0 months:1 days:0 hours:0 minutes:0 seconds:0];
        } else newDate = [selectedDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
    } else if (firstCharacter >= '0' && firstCharacter <= '9') {
        // For consistency with List Manager as documented, reset the typeahead buffer after twice the delay until key repeat (in ticks).
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        int keyRepeatTicks = [defaults integerForKey: @"InitialKeyRepeat"];
        NSTimeInterval resetDelay;

        if (keyRepeatTicks == 0) keyRepeatTicks = 35; // default may be missing; if so, set default

        resetDelay = MIN(2.0 / 60.0 * keyRepeatTicks, 2.0);

        if (typed == nil) typed = [[NSMutableString alloc] init];
        else if (typeSelectResetTime != nil && [typeSelectResetTime compare: [NSDate date]] == NSOrderedAscending)
            [typed setString: @""];
        if ([typed length] != 0 || firstCharacter != '0') // don't construct a string 000... because it'll mess up length measurement for deciding whether to select a day
            CFStringAppendCharacters((CFMutableStringRef)typed, &firstCharacter, 1);

        [typeSelectResetTime release];
        typeSelectResetTime = [[NSDate dateWithTimeIntervalSinceNow: resetDelay] retain];

        int length = [typed length];
        if (length > 2) {
            [typed deleteCharactersInRange: NSMakeRange(0, length - 2)];
            length = 2;
        }
        if (length == 1 || length == 2) {
            int dayOfMonth = [typed intValue], daysInMonth = [selectedDay numberOfDaysInMonth];
            if (dayOfMonth >= daysInMonth) {
                [typed deleteCharactersInRange: NSMakeRange(0, 1)];
                dayOfMonth = [typed intValue];
            }
            if (dayOfMonth > 0)
                newDate = [selectedDay dateByAddingYears:0 months:0 days:dayOfMonth - [selectedDay dayOfMonth] hours:0 minutes:0 seconds:0];
        }
    }
    if (newDate != nil) {
        if (flags.targetApprovesDateSelection && ![[self target] calendarView: self shouldSelectDate: newDate])
            return;
        if (([selectedDay monthOfYear] != [newDate monthOfYear]) || ([selectedDay yearOfCommonEra] != [newDate yearOfCommonEra]))
            [self setVisibleMonth: newDate];
        [self setSelectedDay: newDate];
        return;
    }
    [super keyDown: theEvent];
}

@end


@implementation OACalendarView (Private)

- (NSButton *)_createButtonWithFrame:(NSRect)buttonFrame;
{
    NSButton *button;
    
    button = [[NSButton alloc] initWithFrame:buttonFrame];
    [button setBezelStyle:NSShadowlessSquareBezelStyle];
    [button setBordered:NO];
    [button setImagePosition:NSImageOnly];
    [button setTarget:self];
    [button setContinuous:YES];
//    [self addSubview:button];
    [buttons addObject:button];
    [button release];

    return button;
}

- (void)setTarget:(id)value;
{
    [super setTarget:value];
    flags.targetProvidesHighlightMask = [value respondsToSelector:@selector(calendarView:highlightMaskForVisibleMonth:)];
    flags.targetWatchesCellDisplay = [value respondsToSelector:@selector(calendarView:willDisplayCell:forDate:)];
    flags.targetApprovesDateSelection = [value respondsToSelector:@selector(calendarView:shouldSelectDate:)];
    flags.targetWatchesVisibleMonth = [value respondsToSelector:@selector(calendarView:didChangeVisibleMonth:)];
    flags.targetReceivesDismiss = [value respondsToSelector:@selector(calendarViewShouldDismiss:)];
}

- (void)_calculateSizes;
{
    NSSize cellSize;
    NSRect viewBounds;
    NSRect topRect;
    NSRect discardRect;
    NSRect tempRect;

    viewBounds = [self bounds];
    
    // get the grid cell width (subtract 1.0 from the bounds width to allow for the border)
    columnWidth = floorf((viewBounds.size.width - 1.0f) / OACalendarViewNumDaysPerWeek);
    viewBounds.size.width = (columnWidth * OACalendarViewNumDaysPerWeek) + 1.0f;
    
    // resize the month & year view to be the same width as the grid
    [monthAndYearView setFrameSize:NSMakeSize(viewBounds.size.width, [monthAndYearView frame].size.height)];

    // get the rect for the month and year text field cell
    cellSize = [monthAndYearTextFieldCell cellSize];
    NSDivideRect(viewBounds, &topRect, &gridHeaderAndBodyRect, ceilf(cellSize.height + OACalendarViewSpaceBetweenMonthYearAndGrid), NSMinYEdge);
    NSDivideRect(topRect, &discardRect, &monthAndYearRect, floorf((viewBounds.size.width - cellSize.width) / 2), NSMinXEdge);
    monthAndYearRect.size.width = cellSize.width;
    
    tempRect = gridHeaderAndBodyRect;
    // leave space for a one-pixel border on each side
    tempRect.size.width -= 2.0f;
    tempRect.origin.x += 1.0f;
    // leave space for a one-pixel border at the bottom (the top already looks fine)
    tempRect.size.height -= 1.0f;

    // get the grid header rect
    cellSize = [dayOfWeekCell[0] cellSize];
    NSDivideRect(tempRect, &gridHeaderRect, &gridBodyRect, ceilf(cellSize.height), NSMinYEdge);
    
    // get the grid row height (add 1.0 to the body height because while we can't actually draw on that extra pixel, our bottom row doesn't have to draw a bottom grid line as there's a border right below us, so we need to account for that, which we do by pretending that next pixel actually does belong to us)
    rowHeight = floorf((gridBodyRect.size.height + 1.0f) / OACalendarViewMaxNumWeeksIntersectedByMonth);
    
    // get the grid body rect
    gridBodyRect.size.height = (rowHeight * OACalendarViewMaxNumWeeksIntersectedByMonth) - 1.0f;
    
    // adjust the header and body rect to account for any adjustment made while calculating even row heights
    gridHeaderAndBodyRect.size.height = NSMaxY(gridBodyRect) - NSMinY(gridHeaderAndBodyRect) + 1.0f;
}

- (void)_drawDaysOfMonthInRect:(NSRect)rect;
{
    NSRect cellFrame;
    NSRect dayOfMonthFrame;
    NSRect discardRect;
    int visibleMonthIndex;
    NSCalendarDate *thisDay;
    int index, row, column;
    NSSize cellSize;
    BOOL isFirstResponder = ([[self window] firstResponder] == self);

    // the cell is actually one pixel shorter than the row height, because the row height includes the bottom grid line (or the top grid line, depending on which way you prefer to think of it)
    cellFrame.size.height = rowHeight - 1.0f;
    // the cell would actually be one pixel narrower than the column width but we don't draw vertical grid lines. instead, we want to include the area that would be grid line (were we drawing it) in our cell, because that looks a bit better under the header, which _does_ draw column separators. actually, we want to include the grid line area on _both sides_ or it looks unbalanced, so we actually _add_ one pixel, to cover that. below, our x position as we draw will have to take that into account. note that this means that sunday and saturday overwrite the outside borders, but the outside border is drawn last, so it ends up ok. (if we ever start drawing vertical grid lines, change this to be - 1.0, and adjust the origin appropriately below.)
    cellFrame.size.width = columnWidth + 1.0f;

    cellSize = [dayOfMonthCell cellSize];
    
    visibleMonthIndex = [visibleMonth monthOfYear];

    thisDay = [visibleMonth dateByAddingYears:0 months:0 days:-[visibleMonth dayOfWeek] hours:0 minutes:0 seconds:0];

    for (row = column = index = 0; index < OACalendarViewMaxNumWeeksIntersectedByMonth * OACalendarViewNumDaysPerWeek; index++) {
        NSColor *textColor;
        BOOL isVisibleMonth;

        // subtract 1.0 from the origin because we're including the area where vertical grid lines would be were we drawing them
        cellFrame.origin.x = rect.origin.x + (column * columnWidth) - 1.0f;
        cellFrame.origin.y = rect.origin.y + (row * rowHeight);

        [dayOfMonthCell setIntValue:[thisDay dayOfMonth]];
        isVisibleMonth = ([thisDay monthOfYear] == visibleMonthIndex);

        if (flags.showsDaysForOtherMonths || isVisibleMonth) {
            if (selectedDay) {
                BOOL shouldHighlightThisDay = NO;

                // We could just check if thisDay is in [self selectedDays]. However, that makes the selection look somewhat weird when we
                // are selecting by weekday, showing days for other months, and the visible month is the previous/next from the selected day.
                // (Some of the weekdays are shown as highlighted, and later ones are not.)
                // So, we fib a little to make things look better.
                switch (selectionType) {
                    case OACalendarViewSelectByDay:
                        shouldHighlightThisDay = ([selectedDay dayOfCommonEra] == [thisDay dayOfCommonEra]);
                        break;
                        
                    case OACalendarViewSelectByWeek:
                        shouldHighlightThisDay = [selectedDay isInSameWeekAsDate:thisDay];
                        break;
                        
                    case OACalendarViewSelectByWeekday:
                        shouldHighlightThisDay = ([selectedDay monthOfYear] == visibleMonthIndex && [selectedDay dayOfWeek] == [thisDay dayOfWeek]);
                        break;
                        
                    default:
                        [NSException raise:NSInvalidArgumentException format:@"OACalendarView: Unknown selection type: %d", selectionType];
                        break;
                }
                
                if (shouldHighlightThisDay) {
                    [(isFirstResponder ? [NSColor selectedControlColor] : [NSColor secondarySelectedControlColor]) set];
                    NSRectFill(cellFrame);
                }
            }
            
            if (flags.targetWatchesCellDisplay) {
                [[self target] calendarView:self willDisplayCell:dayOfMonthCell forDate:thisDay];
            } else {
                if ((dayHighlightMask & (1 << index)) == 0) {
                    textColor = (isVisibleMonth ? [NSColor blackColor] : [NSColor grayColor]);
                } else {
                    textColor = [NSColor blueColor];
                }
                [dayOfMonthCell setTextColor:textColor];
            }
            NSDivideRect(cellFrame, &discardRect, &dayOfMonthFrame, floorf((cellFrame.size.height - cellSize.height) / 2.0f), NSMinYEdge);
            [dayOfMonthCell drawWithFrame:dayOfMonthFrame inView:self];
        }
        
        thisDay = [thisDay dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
        column++;
        if (column > OACalendarViewMaxNumWeeksIntersectedByMonth) {
            column = 0;
            row++;
        }
    }
}

- (void)_drawGridInRect:(NSRect)rect;
{
    NSPoint pointA;
    NSPoint pointB;
    int weekIndex;
    
    // we will be adding the row height each time, so subtract 1.0 (the grid thickness) from the starting y position (for example, if starting y = 0 and row height = 10, then starting y + row height = 10, so we would draw at pixel 10... which is the 11th pixel. Basically, we subtract 1.0 to make the result zero-based, so that we draw at pixel 10 - 1 = 9, which is the 10th pixel)
    // add 0.5 to move to the center of the pixel before drawing a line 1.0 pixels thick, centered around 0.0 (which would mean half a pixel above the starting point and half a pixel below - not what we want)
    // we could just subtract 0.5, but I think this is clearer, and the compiler will optimize it to the appropriate value for us
    pointA = NSMakePoint(NSMinX(rect), NSMinY(rect) - 1.0f + 0.5f);
    pointB = NSMakePoint(NSMaxX(rect), NSMinY(rect) - 1.0f + 0.5f);
    
    [[NSColor controlHighlightColor] set];
    for (weekIndex = 1; weekIndex < OACalendarViewMaxNumWeeksIntersectedByMonth; weekIndex++) {
        pointA.y += rowHeight;
        pointB.y += rowHeight;
        [NSBezierPath strokeLineFromPoint:pointA toPoint:pointB];
    }
    
#if 0
// we would do this if we wanted to draw columns in the grid
    {
        int dayIndex;
        
        // see aov for explanation of why we subtract 1.0 and add 0.5 to the x position
        pointA = NSMakePoint(NSMinX(rect) - 1.0 + 0.5, NSMinY(rect));
        pointB = NSMakePoint(NSMinX(rect) - 1.0 + 0.5, NSMaxY(rect));
        
        for (dayIndex = 1; dayIndex < OACalendarViewNumDaysPerWeek; dayIndex++) {
            pointA.x += columnWidth;
            pointB.x += columnWidth;
            [NSBezierPath strokeLineFromPoint:pointA toPoint:pointB];
        }
    }
#endif
}

- (float)_maximumDayOfWeekWidth;
{
    float maxWidth;
    int index;

    maxWidth = 0;
    for (index = 0; index < OACalendarViewNumDaysPerWeek; index++) {
        NSSize cellSize;

        cellSize = [dayOfWeekCell[index] cellSize];
        if (maxWidth < cellSize.width)
            maxWidth = cellSize.width;
    }

    return ceilf(maxWidth);
}

- (NSSize)_maximumDayOfMonthSize;
{
    NSSize maxSize;
    int index;

    maxSize = NSZeroSize; // I'm sure the height doesn't change, but I need to know the height anyway.
    for (index = 1; index <= 31; index++) {
        NSString *str;
        NSSize cellSize;

        str = [NSString stringWithFormat:@"%d", index];
        [dayOfMonthCell setStringValue:str];
        cellSize = [dayOfMonthCell cellSize];
        if (maxSize.width < cellSize.width)
            maxSize.width = cellSize.width;
        if (maxSize.height < cellSize.height)
            maxSize.height = cellSize.height;
    }

    maxSize.width = ceil(maxSize.width);
    maxSize.height = ceil(maxSize.height);

    return maxSize;
}

- (float)_minimumColumnWidth;
{
    float dayOfWeekWidth;
    float dayOfMonthWidth;
    
    dayOfWeekWidth = [self _maximumDayOfWeekWidth];	// we don't have to add 1.0 because the day of week cell whose width is returned here includes it's own border
    dayOfMonthWidth = [self _maximumDayOfMonthSize].width + 1.0f;	// add 1.0 to allow for the grid. We don't actually draw the vertical grid, but we treat it as if there was one (don't respond to clicks "on" the grid, we have a vertical separator in the header, etc.) 
    return (dayOfMonthWidth > dayOfWeekWidth) ? dayOfMonthWidth : dayOfWeekWidth;
}

- (float)_minimumRowHeight;
{
    return [self _maximumDayOfMonthSize].height + 1.0f;	// add 1.0 to allow for a bordering grid line
}

- (NSCalendarDate *)_hitDateWithLocation:(NSPoint)targetPoint;
{
    int hitRow, hitColumn;
    int firstDayOfWeek, targetDayOfMonth;
    NSPoint offset;

    if (NSPointInRect(targetPoint, gridBodyRect) == NO)
        return nil;

    firstDayOfWeek = [[visibleMonth firstDayOfMonth] dayOfWeek];

    offset = NSMakePoint(targetPoint.x - gridBodyRect.origin.x, targetPoint.y - gridBodyRect.origin.y);
    // if they exactly hit the grid between days, treat that as a miss
    if ((selectionType != OACalendarViewSelectByWeekday) && (((int)offset.y % (int)rowHeight) == 0))
        return nil;
    // if they exactly hit the grid between days, treat that as a miss
    if ((selectionType != OACalendarViewSelectByWeek) && ((int)offset.x % (int)columnWidth) == 0)
        return nil;
    hitRow = (int)(offset.y / rowHeight);
    hitColumn = (int)(offset.x / columnWidth);

    targetDayOfMonth = (hitRow * OACalendarViewNumDaysPerWeek) + hitColumn - firstDayOfWeek + 1;
    if (!flags.showsDaysForOtherMonths && (targetDayOfMonth < 1 || targetDayOfMonth > [visibleMonth numberOfDaysInMonth]))
        return nil;

    return [visibleMonth dateByAddingYears:0 months:0 days:targetDayOfMonth-1 hours:0 minutes:0 seconds:0];
}

- (NSCalendarDate *)_hitWeekdayWithLocation:(NSPoint)targetPoint;
{
    int hitDayOfWeek;
    int firstDayOfWeek, targetDayOfMonth;
    float offsetX;

    if (NSPointInRect(targetPoint, gridHeaderRect) == NO)
        return nil;
    
    offsetX = targetPoint.x - gridHeaderRect.origin.x;
    // if they exactly hit a border between weekdays, treat that as a miss (besides being neat in general, this avoids the problem where clicking on the righthand border would result in us incorrectly calculating that the _first_ day of the week was hit)
    if (((int)offsetX % (int)columnWidth) == 0)
        return nil;
    
    hitDayOfWeek = offsetX / columnWidth;

    firstDayOfWeek = [[visibleMonth firstDayOfMonth] dayOfWeek];
    if (hitDayOfWeek >= firstDayOfWeek)
        targetDayOfMonth = hitDayOfWeek - firstDayOfWeek + 1;
    else
        targetDayOfMonth = hitDayOfWeek + OACalendarViewNumDaysPerWeek - firstDayOfWeek + 1;

    return [visibleMonth dateByAddingYears:0 months:0 days:targetDayOfMonth-1 hours:0 minutes:0 seconds:0];
}

@end
