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
    IBOutlet NSTextView *body;
    IBOutlet NSBox *bodyBox;
    IBOutlet NSTabView *progressTabs;
    IBOutlet NSProgressIndicator *progress;
    NSMutableArray *headings;
    float maxHeadingWidth;
    NSDictionary *headingAttributes;
}

+ (NJRReadMeController *)readMeControllerWithRTFDocument:(NSString *)aPath;
- (id)initWithRTFDocument:(NSString *)aPath;

- (IBAction)contentsClicked:(NSTableView *)sender;

@end
