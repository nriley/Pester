#import "NJRFSObjectSelector.h"
#import "NSMenuItem-NJRExtensions.h"
#import "NSString-NJRExtensions.h"
#include <Carbon/Carbon.h>

static NSImage *PopupTriangleImage = nil;
static NSSize PopupTriangleSize;

@interface NJRFSObjectSelector (NSOpenPanelRuntime)
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@implementation NJRFSObjectSelector

- (void)_initSelector;
{
    if (PopupTriangleImage == nil) {
        PopupTriangleImage = [[NSImage imageNamed: @"Popup triangle"] retain];
        PopupTriangleSize = [PopupTriangleImage size];
    }
    canChooseFiles = YES; canChooseDirectories = NO;
    [self setAlias: nil];
    [[self cell] setHighlightsBy: NSChangeBackgroundCell];
    [[self cell] setGradientType: NSGradientNone];
    [self registerForDraggedTypes:
        [NSArray arrayWithObjects: NSFilenamesPboardType, NSURLPboardType, nil]];
}

- (void)dealloc;
{
    [selectedAlias release];
    [fileTypes release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder;
{
    if ( (self = [super initWithCoder: coder]) != nil) {
        [self _initSelector];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame;
{
    if ( (self = [super initWithFrame: frame]) != nil) {
        [self _initSelector];
    }
    return self;
}

- (void)drawRect:(NSRect)rect;
{
    NSRect boundsRect = [self bounds];
    [super drawRect: rect];
    if (dragAccepted) {
        [[NSColor selectedControlColor] set];
        [NSBezierPath setDefaultLineWidth: 2];
        [NSBezierPath strokeRect: NSInsetRect(boundsRect, 2, 2)];
    } else if (selectedAlias != nil && [self isEnabled]) {
        // equivalent to popup triangle location for large bezel in Carbon
        [PopupTriangleImage compositeToPoint: NSMakePoint(NSMaxX(boundsRect) - PopupTriangleSize.width - 5, NSMaxY(boundsRect) - 5) operation: NSCompositeSourceOver];
    }
}

- (BOOL)acceptsPath:(NSString *)path;
{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir;

    if (![fm fileExistsAtPath: path isDirectory: &isDir]) return NO;

    if (isDir) return canChooseDirectories;
    if (canChooseFiles) {
        NSEnumerator *e = [fileTypes objectEnumerator];
        NSString *extension = [path pathExtension];
        NSString *hfsType = NSHFSTypeOfFile(path);
        NSString *fileType;
        
        while ( (fileType = [e nextObject]) != nil) {
            if ([fileType isEqualToString: extension] || [fileType isEqualToString: hfsType])
                return YES;
        }
    }
    return NO;
}

- (IBAction)select:(id)sender;
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    NSString *path = [selectedAlias fullPath];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setCanChooseDirectories: canChooseDirectories];
    [openPanel setCanChooseFiles: canChooseFiles];
    [openPanel beginSheetForDirectory: [path stringByDeletingLastPathComponent]
                                 file: [path lastPathComponent]
                                types: fileTypes
                       modalForWindow: [self window]
                        modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                          contextInfo: nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
{
    [sheet close];

    if (returnCode == NSOKButton) {
        NSArray *files = [sheet filenames];
        NSAssert1([files count] == 1, @"%d items returned, only one expected", [files count]);
        [self setPath: [files objectAtIndex: 0]];
		if ([self target] != nil && [[self target] respondsToSelector:[self action]])
			[[self target] performSelector: [self action] withObject: self];
    }
}

- (void)revealInFinder:(NSMenuItem *)sender;
{
    NSString *path = [sender representedObject];
    if (path == nil) return;
    [[NSWorkspace sharedWorkspace] selectFile: path inFileViewerRootedAtPath: @""];
}

- (void)setAlias:(BDAlias *)alias;
{
    if (selectedAlias != alias) {
        [selectedAlias release];
        selectedAlias = [alias retain];
    }

    if (alias != nil) { // alias is set
        NSString *path = [alias fullPath];
        NSString *revealPath = nil;
        NSMenu *menu = [[NSMenu alloc] initWithTitle: @""];
        NSFileManager *fmgr = [NSFileManager defaultManager];
        NSMenuItem *item;
        if (path != nil) { // can resolve alias
	    [self setImage: [[NSWorkspace sharedWorkspace] iconForFile: path]];
            {	// set image first so titleRectForBounds: returns the correct value
                NSMutableString *title = [[fmgr displayNameAtPath: path] mutableCopy];
                NSDictionary *fontAttributes = [[self attributedTitle] fontAttributesInRange: NSMakeRange(0, 0)];
                [title truncateToWidth: [[self cell] titleRectForBounds: [self bounds]].size.width - PopupTriangleSize.width by: NSLineBreakByTruncatingMiddle withAttributes: fontAttributes];
                [self setTitle: title];
                [title release];
            }
            do {
                NSAssert1(![path isEqualToString: revealPath], @"Stuck on path |%@|", [alias fullPath]);
                item = [menu addItemWithTitle: [fmgr displayNameAtPath: path]
                                       action: @selector(revealInFinder:)
                                keyEquivalent: @""];
                [item setTarget: self];
                [item setRepresentedObject: revealPath];
                [item setImageFromPath: path];
                revealPath = path;
                path = [path stringByDeletingLastPathComponent];
            } while (![revealPath isEqualToString: @"/"] && ![path isEqualToString: @"/Volumes"]);
            [[self cell] setMenu: menu];
        } else {
            [self setImage: nil];
            [self setTitle: @"(not available)"];
            [[self cell] setMenu: nil];
        }
	[menu release];
    } else {
        [self setImage: nil];
        [self setTitle: @"(none selected)"];
        [[self cell] setMenu: nil];
    }
    [self setEnabled: isEnabled];
}

- (BOOL)isEnabled;
{
    return isEnabled;
}

- (void)setEnabled:(BOOL)enabled;
{
    isEnabled = enabled;
    [super setEnabled: enabled ? selectedAlias != nil : NO];
}

- (void)rightMouseDown:(NSEvent *)theEvent;
{
    [self mouseDown: theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent;
{
    [self mouseDown: theEvent];
}

extern MenuRef _NSGetCarbonMenu(NSMenu *menu);

- (void)mouseDown:(NSEvent *)theEvent;
{
    if (![self isEnabled]) return;
    
    NSMenu *menu = [[self cell] menu];
    MenuRef mRef = _NSGetCarbonMenu(menu);

    if (mRef == NULL) {
        NSMenu *appMenu = [[[NSApp mainMenu] itemWithTitle: @""] submenu];
        if (appMenu != nil) {
            NSMenuItem *item = [appMenu addItemWithTitle: @"" action: NULL keyEquivalent: @""];
            [appMenu setSubmenu: menu forItem: item];
            [appMenu removeItem: item];
        }
        mRef = _NSGetCarbonMenu(menu);
    }

    ChangeMenuAttributes(mRef, kMenuAttrExcludesMarkColumn, 0);
    theEvent = [NSEvent mouseEventWithType: [theEvent type]
                                  location: [self convertPoint: NSMakePoint(-1, 1) toView: nil]
                             modifierFlags: [theEvent modifierFlags]
                                 timestamp: [theEvent timestamp]
                              windowNumber: [theEvent windowNumber]
                                   context: [theEvent context]
                               eventNumber: [theEvent eventNumber]
                                clickCount: [theEvent clickCount]
                                  pressure: [theEvent pressure]];

    // XXX otherwise Cocoa thoughtfully doesn't give me the font I want
    NSFont *font = [[self cell] font];
    [NSMenu popUpContextMenu: menu withEvent: theEvent forView: self withFont: 
     [NSFont fontWithName: [font fontName] size: [font pointSize] - 0.001]];
}

- (BDAlias *)alias;
{
    return selectedAlias;
}

- (void)setPath:(NSString *)path;
{
    [self setAlias: [BDAlias aliasWithPath: path]];
}

- (BOOL)canChooseDirectories;
{
    return canChooseDirectories;
}

- (BOOL)canChooseFiles;
{
    return canChooseFiles;
}

- (void)setCanChooseDirectories:(BOOL)flag;
{
    canChooseDirectories = flag;
}

- (void)setCanChooseFiles:(BOOL)flag;
{
    canChooseFiles = flag;
}

- (NSArray *)fileTypes;
{
    return fileTypes;
}

- (void)setFileTypes:(NSArray *)types;
{
    if (fileTypes == types) return;
    
    [fileTypes release];
    fileTypes = [types retain];
}

@end


@implementation NJRFSObjectSelector (NSDraggingDestination)

- (BOOL)acceptsDragFrom:(id <NSDraggingInfo>)sender;
{
    NSURL *url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];

    if (url == nil || ![url isFileURL]) return NO;
    return [self acceptsPath: [url path]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
{
    if ([self acceptsDragFrom: sender] && [sender draggingSourceOperationMask] &
        (NSDragOperationCopy | NSDragOperationLink)) {
        dragAccepted = YES;
        [self setNeedsDisplay: YES];
        return NSDragOperationLink;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender;
{
    dragAccepted = NO;
    [self setNeedsDisplay: YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
    dragAccepted = NO;
    [self setNeedsDisplay: YES];
    return [self acceptsDragFrom: sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
{
    if ([sender draggingSource] != self) {
        NSURL *url = [NSURL URLFromPasteboard: [sender draggingPasteboard]];
        if (url == nil) return NO;
        [self setPath: [url path]];
		if ([self target] != nil && [[self target] respondsToSelector:[self action]])
			[[self target] performSelector: [self action] withObject: self];
    }
    return YES;
}

@end
