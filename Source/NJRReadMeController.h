//
//  NJRReadMeController.h
//  Pester
//
//  Created by Nicholas Riley on Tue Feb 18 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRReadMeController : NSWindowController {
    IBOutlet NSSplitView *splitter;
    IBOutlet NSTableView *contents;
    IBOutlet NSTextFieldCell *headingCell;
    IBOutlet NSTextView *body;
    IBOutlet NSBox *bodyBox;
    NSMutableArray *headings;
    NSDictionary *headingAttributes;
}

+ (NJRReadMeController *)readMeControllerWithRTFDocument:(NSString *)aPath;
- (id)initWithRTFDocument:(NSString *)aPath;

@end
