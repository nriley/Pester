//
//  NJRHistoryTrackingComboBox.h
//  DockCam
//
//  Created by Nicholas Riley on Fri Jun 28 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NJRHistoryTrackingComboBox : NSComboBox {

}

- (IBAction)removeEntry:(id)sender;
- (IBAction)clearAllEntries:(id)sender;

@end
