//
//  NJRIntervalField.h
//  Pester
//
//  Created by Nicholas Riley on Wed Dec 25 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRIntervalField : NSTextField {
    IBOutlet NSPopUpButton *intervalUnits;
}

- (NSTimeInterval)interval;
- (BOOL)setInterval:(NSTimeInterval)interval; // returns false if out of range

- (void)handleDidFailToFormatString:(NSString *)string errorDescription:(NSString *)error label:(NSString *)label;

@end
