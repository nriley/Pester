//
//  NJRTableView.h
//  Pester
//
//  Created by Nicholas Riley on Sun Nov 17 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRTableView : NSTableView {
    NSMutableString *typed;
    IBOutlet id typeSelectDisplay;
}

- (id)typeSelectDisplay;
- (void)resetTypeSelect;

@end

@interface NSObject (NJRTableViewDelegate)

- (void)tableView:(NSTableView *)aTableView selectRowMatchingString:(NSString *)matchString;

@end

@interface NSObject (NJRTableViewDataSource)

- (void)removeSelectedRowsFromTableView:(NSTableView *)tableView;
- (NSString *)toolTipForRow:(int)rowIndex;

@end
