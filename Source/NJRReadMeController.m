//
//  NJRReadMeController.m
//  Pester
//
//  Created by Nicholas Riley on Tue Feb 18 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRReadMeController.h"
#import "NSString-NJRExtensions.h"

@interface NJRHelpContentsEntry : NSObject {
    unsigned level;
    NSString *description;
    NSRange range;
}

+ (NJRHelpContentsEntry *)headingLevel:(int)aLevel description:(NSString *)aDescription range:(NSRange)aRange;
- (id)initWithLevel:(int)aLevel description:(NSString *)aDescription range:(NSRange)aRange;

- (NSString *)description;
- (NSRange)range;
- (NSMutableString *)displayString;

@end

@implementation NJRHelpContentsEntry

+ (NJRHelpContentsEntry *)headingLevel:(int)aLevel description:(NSString *)aDescription range:(NSRange)aRange;
{
    return [[[self alloc] initWithLevel: aLevel description: aDescription range: aRange] autorelease];
}

- (id)initWithLevel:(int)aLevel description:(NSString *)aDescription range:(NSRange)aRange;
{
    if ( (self = [super init]) != nil) {
        level = aLevel;
        description = [[aDescription stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
        range = aRange;
    }
    return self;
}

- (void)dealloc;
{
    [description release];
    [super dealloc];
}

- (NSString *)description;
{
    return [NSString stringWithFormat: @"%u > %@ %@", level, description, NSStringFromRange(range)];
}

- (NSRange)range;
{
    return range;
}

- (NSMutableString *)displayString;
{
    NSMutableString *s = [[NSMutableString alloc] init];

    unsigned i;
    for (i = 0 ; i < level ; i++) {
        [s appendString: @"ÊÊ"];
    }
    [s appendString: description];
    return [s autorelease];
}

@end

@interface NJRReadMeController (Private)
- (void)_saveSplit;
- (void)_restoreSplit;
@end

@implementation NJRReadMeController

static NJRReadMeController *sharedController = nil;

+ (NJRReadMeController *)readMeControllerWithRTFDocument:(NSString *)aPath;
{
    return [[self alloc] initWithRTFDocument: aPath];
}

- (id)initWithRTFDocument:(NSString *)aPath;
{
    if (sharedController != nil) {
        [self release];
        [[sharedController window] makeKeyAndOrderFront: sharedController];
        return sharedController;
    }
    if ( (self = [super initWithWindowNibName: @"Read Me"]) != nil) {
        NSWindow *window = [self window];
        [progress setIndeterminate: YES];
        [progressTabs selectTabViewItemWithIdentifier: @"progress"];

        [NSThread detachNewThreadSelector: @selector(readRTF:) toTarget: self withObject: aPath];
        NSString *frameAutosaveName;
        if ( (frameAutosaveName = [window frameAutosaveName]) == nil) {
            // XXX workaround for bug in 10.1.5Ð10.2.4 (at least): autosave name set in IB doesn't show up
            [self setWindowFrameAutosaveName: @"Read Me"];
            frameAutosaveName = [window frameAutosaveName];
        }
        if (frameAutosaveName == nil || ![window setFrameUsingName: frameAutosaveName])
            [window center];
        [self _restoreSplit];

        [window makeKeyAndOrderFront: self];
        sharedController = self;
    }
    return self;
}

- (void)dealloc;
{
    [headings release];
    [headingAttributes release];
    if (sharedController == self) sharedController = nil;
    [super dealloc];
}

- (void)readRTF:(NSString *)aPath;
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSAttributedString *readMe = [[NSAttributedString alloc] initWithPath: aPath documentAttributes: nil];
    if (readMe == nil) {
        [body insertText: [NSString stringWithFormat: @"CanÕt read document Ò%@Ó", [aPath lastPathComponent]]];
    } else {
        NSTextStorage *storage = [body textStorage];
        [storage setAttributedString: readMe];
        [readMe release]; readMe = nil;

        unsigned int length = [storage length];
        [progress setIndeterminate: NO];
        [progress setMaxValue: length];
        NSRange effectiveRange = NSMakeRange(0, 0);
        unsigned int chunkLength = 0;
        NSFont *fontAttr = nil;
        NSString *fontName = nil; float fontSize = 0;
        NSString *heading = nil;

        headings = [[NSMutableArray alloc] init];
        
        // XXX need this instead? (id)attribute:(NSString *)attrName atIndex:(unsigned int)location longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)rangeLimit;
        while (NSMaxRange(effectiveRange) < length) {
            fontAttr = (NSFont *)[storage attribute: NSFontAttributeName
                                            atIndex: NSMaxRange(effectiveRange) effectiveRange: &effectiveRange];
            if (effectiveRange.length < 3) continue;
            fontName = [fontAttr fontName]; fontSize = [fontAttr pointSize];
            chunkLength = effectiveRange.length;
            if ([fontName isEqualToString: @"GillSans-Bold"]) {
                heading = [[storage attributedSubstringFromRange: effectiveRange] string];
                if (fontSize == 24)
                    [headings addObject: [NJRHelpContentsEntry headingLevel: 0 description: [[storage attributedSubstringFromRange: effectiveRange] string] range: effectiveRange]];
                else
                    [headings addObject:
                        [NJRHelpContentsEntry headingLevel: (fontSize == 14) ? 1: 2 description: heading range: effectiveRange]];
            }
            if (fontSize != 14) continue;
            if ([fontName isEqualToString: @"HoeflerText-Black"]) {
                heading = [[storage attributedSubstringFromRange: NSMakeRange(effectiveRange.location, chunkLength + 1)] string];
                switch ([heading characterAtIndex: chunkLength]) {
                    case ':':
                    case ',':
                        break;
                    case ' ':
                        switch ([heading characterAtIndex: chunkLength - 1]) {
                            case ':':
                            case ',':
                                chunkLength--;
                                break;
                            default:
                                continue;
                        }
                        break;
                    default:
                        continue;
                }
                [headings addObject: [NJRHelpContentsEntry headingLevel: 2 description: [heading substringToIndex: chunkLength] range: NSMakeRange(effectiveRange.location, chunkLength)]];
            }
            [progress setDoubleValue: NSMaxRange(effectiveRange)];
        }
    }
    headingAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: [[[contents tableColumnWithIdentifier: @"heading"] dataCell] font], NSFontAttributeName, nil];
    NSEnumerator *e = [headings objectEnumerator];
    NSString *s;
    float width;
    maxHeadingWidth = 0;
    while ( (s = [(NJRHelpContentsEntry *)[e nextObject] displayString]) != nil) {
        width = [s sizeWithAttributes: headingAttributes].width;
        if (width > maxHeadingWidth) maxHeadingWidth = width;
    }
    maxHeadingWidth += 25; // account for scroll bar and frame
    [self _saveSplit];
    [self _restoreSplit];
    
    [contents reloadData];
    [progressTabs selectTabViewItemWithIdentifier: @"completed"];
    [pool release];
}

- (void)_saveSplit;
{
    NSString *frameAutosaveName;
    if ( (frameAutosaveName = [[self window] frameAutosaveName]) != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat: maxHeadingWidth forKey:
            [frameAutosaveName stringByAppendingString: @" maximum contents heading width"]];
        NSBox *contentsBox = [[splitter subviews] objectAtIndex: 0];
        [defaults setBool: [splitter isSubviewCollapsed: contentsBox] forKey:
                [frameAutosaveName stringByAppendingString: @" contents are collapsed"]];
        [defaults synchronize];
    }
}

- (void)_restoreSplit;
{
    NSString *frameAutosaveName;
    BOOL contentsCollapsed = NO;
    if ( (frameAutosaveName = [[self window] frameAutosaveName]) != nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        contentsCollapsed = [defaults boolForKey:
            [frameAutosaveName stringByAppendingString: @" contents are collapsed"]];
        if (maxHeadingWidth == 0) { // don't want to restore 0 if we can't write to defaults
            maxHeadingWidth = [defaults floatForKey:
                [frameAutosaveName stringByAppendingString: @" maximum contents heading width"]];
        }
    }
    NSBox *contentsBox = [[splitter subviews] objectAtIndex: 0];
    if ([splitter isSubviewCollapsed: contentsBox] ||
        (maxHeadingWidth == 0 && !contentsCollapsed)) return;
    if (contentsCollapsed) {
        [splitter performSelectorOnMainThread: @selector(collapseSubview:) withObject: contentsBox waitUntilDone: YES];
        return;
    }
    NSSize contentsSize = [contentsBox frame].size;
    float widthDiff = contentsSize.width - maxHeadingWidth;
    if (widthDiff < 1) return;
    NSSize bodySize = [bodyBox frame].size;
    bodySize.width += widthDiff;
    contentsSize.width -= widthDiff;
    [contentsBox setFrameSize: contentsSize];
    [bodyBox setFrameSize: bodySize];
    [splitter performSelectorOnMainThread: @selector(adjustSubviews) withObject: nil waitUntilDone: NO];
}

- (IBAction)contentsClicked:(NSTableView *)sender;
{
    int row = [sender clickedRow];
    if (row == -1) return;
    NSRange range = [[headings objectAtIndex: row] range];
    [body setSelectedRange: range];
    [body scrollRangeToVisible: range];
}

@end

@implementation NJRReadMeController (NSTableDataSource)

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [headings count];
}

// need to enable column resizing for this to work, otherwise we never get called again
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    NSMutableString *s = [[headings objectAtIndex: row] displayString];
    [s truncateToWidth: [tableView frameOfCellAtColumn: 0 row: row].size.width by: NSLineBreakByTruncatingTail withAttributes: headingAttributes];
    return s;
}

@end

@implementation NJRReadMeController (NSSplitViewDelegate)

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedCoord ofSubviewAt:(int)offset;
{
    return MAX(proposedCoord, 80);
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedCoord ofSubviewAt:(int)offset;
{
    return MIN(proposedCoord, maxHeadingWidth);
}

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize;
{
    NSSize newSize = [sender frame].size;
    NSBox *contentsBox = [[splitter subviews] objectAtIndex: 0];
    NSSize contentsSize = [contentsBox frame].size;
    NSSize bodySize = [bodyBox frame].size;
    contentsSize.height += newSize.height - oldSize.height;
    [contentsBox setFrameSize: contentsSize];
    bodySize.width += newSize.width - oldSize.width;
    bodySize.height += newSize.height - oldSize.height;
    [bodyBox setFrameSize: bodySize];
    [sender adjustSubviews];
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview;
{
    return [contents isDescendantOf: subview];
}

@end

@implementation NJRReadMeController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    [self _saveSplit];
    [self autorelease];
}

@end