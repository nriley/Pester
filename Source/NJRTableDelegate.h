//
//  NJRTableDelegate.h
//  Pester
//
//  Created by Nicholas Riley on Sun Oct 27 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRTableDelegate : NSObject {
    IBOutlet NSTableView *tableView;
    NSTableColumn *sortingColumn;
    NSString *sortingKey;
    BOOL sortDescending;

    id oData; // XXX ???
}

@end
