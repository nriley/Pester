//
//  PSDateCompletions.h
//  Pester
//
//  Created by Nicholas Riley on Sun Feb 16 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>

@class PSDateFieldEditor;

@interface PSTimeDateEditor : NSObject {
    NSTextField *timeOfDay;
    NSTextField *timeDate;
    NSPopUpButton *timeDateCompletions;
    PSDateFieldEditor *dateFieldEditor;
    id controller;
}

- (id)initWithTimeField:(NSTextField *)timeOfDay dateField:(NSTextField *)timeDate completions:(NSPopUpButton *)timeDateCompletions controller:(id)controller;

- (PSDateFieldEditor *)dateFieldEditor;

@end
