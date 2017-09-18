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
- (NSString *)displayString;

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

- (NSString *)displayString;
{
    NSMutableString *s = [[NSMutableString alloc] init];

    unsigned i;
    for (i = 0 ; i < level ; i++) {
        [s appendString: @"\t"];
    }
    [s appendString: description];
    return [s autorelease];
}

@end

@interface NJRReadMeController ()
- (void)readRTF:(NSString *)aPath;
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
        NSString *frameAutosaveName = [window frameAutosaveName];
        if (![window setFrameUsingName: frameAutosaveName])
            [window center];

        // set up paragraph style for heading indentation
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        NSMutableArray *tabStops = [[NSMutableArray alloc] initWithCapacity: 2];
        for (unsigned i = 1 ; i <= 2 ; i++) {
            NSTextTab *tabStop = [[NSTextTab alloc] initWithType: NSLeftTabStopType location: i * 10];
            [tabStops addObject: tabStop];
            [tabStop release];
        }
        [paragraphStyle setTabStops: tabStops];
        [tabStops release];
        headingAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: paragraphStyle, NSParagraphStyleAttributeName, nil];
        [paragraphStyle release];

        // remove NJRSplitView save information
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey: [frameAutosaveName stringByAppendingString: @" maximum contents heading width"]];
        [defaults removeObjectForKey: [frameAutosaveName stringByAppendingString: @" contents are collapsed"]];

        [self readRTF: aPath];

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
        [body insertText: [NSString stringWithFormat: NSLocalizedString(@"Can't read document '%@'", "Message displayed in in place of read me contents when read me file could not be read; %@ replaced by last path component of filename, e.g. 'Read Me.rtfd'"), [aPath lastPathComponent]]];
    } else {
        NSTextStorage *storage = [body textStorage];
        [[body layoutManager] setBackgroundLayoutEnabled: NO];
        [storage setAttributedString: readMe];
        [readMe release]; readMe = nil;

        NSUInteger length = [storage length];
        NSRange effectiveRange = NSMakeRange(0, 0);
        NSUInteger chunkLength = 0;
        NSFont *fontAttr = nil;
        NSString *fontName = nil; CGFloat fontSize = 0;
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
        }
    }
    NSMutableDictionary *allHeadingAttributes = [headingAttributes mutableCopy];
    [allHeadingAttributes setObject: [headingCell font] forKey: NSFontAttributeName];
    NSEnumerator *e = [headings objectEnumerator];
    NSString *s;
    CGFloat width;
    CGFloat maxHeadingWidth = 0;
    while ( (s = [(NJRHelpContentsEntry *)[e nextObject] displayString]) != nil) {
        width = [s sizeWithAttributes: allHeadingAttributes].width;
        if (width > maxHeadingWidth) maxHeadingWidth = width;
    }
    [allHeadingAttributes release];
    CGFloat maxContentsWidth = maxHeadingWidth + 25; // account for scroll bar and frame
    NSScrollView *contentsScrollView = contents.enclosingScrollView;
    [contentsScrollView addConstraint: [NSLayoutConstraint constraintWithItem: contentsScrollView attribute: NSLayoutAttributeWidth relatedBy: NSLayoutRelationLessThanOrEqual toItem: nil attribute: NSLayoutAttributeNotAnAttribute multiplier: 1.0 constant: maxContentsWidth]];

    [contents reloadData];
    [[body layoutManager] setBackgroundLayoutEnabled: YES];
    [pool release];
}

@end

@implementation NJRReadMeController (NSTableViewDelegate)

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row;
{
    NSRange range = [[headings objectAtIndex: row] range];
    [body setSelectedRange: range];
    [body scrollRangeToVisible: range];

    return YES;
}

@end

@implementation NJRReadMeController (NSTableDataSource)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    return [headings count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
    // Note: Returning an attributed string here, even one which only specifies heading attributes, suppresses some special behavior ("squeezed" text and bold text for the selected rhow) compared with returning a regular string.
    // IMO, squeezed text is confusing in a source list; non-bold text is slightly harder to read, but by no means disastrous, and prevents any compression/ellipsization of text because we compute the optimal width based on the non-bold text.  It also bypasses some OS X bugs which display broken tooltips (e.g. with shadowing in place) when mousing over a selected item in a source list.
    return [[[NSAttributedString alloc] initWithString: [[headings objectAtIndex: row] displayString]
                                            attributes: headingAttributes]
            autorelease];
}

@end

@implementation NJRReadMeController (NSSplitViewDelegate)

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview;
{
    return [contents isDescendantOf: subview];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex;
{
    // XXX never called on 10.11 (r. 22675408)
    return [contents isDescendantOf: subview];
}

@end

@implementation NJRReadMeController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    [self autorelease];
}

@end
