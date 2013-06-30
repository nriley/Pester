//
//  NJRTableDelegate.h
//  Pester
//
//  Created by Nicholas Riley on Sun Oct 27 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NJRTableView.h"


@interface NJRTableDelegate : NSObject <NSTableViewDelegate, NJRTableViewDelegate> {
    IBOutlet NJRTableView *tableView;
    NSTableColumn *sortingColumn;
    NSString *sortingKey;
    BOOL sortDescending;

    NSMutableArray *reorderedData;
}

- (NSMutableArray *)reorderedDataForData:(NSArray *)data;

- (NSSet *)selectedItems;
- (void)selectItems:(NSSet *)inSelectedItems;

@end