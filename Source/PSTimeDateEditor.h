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

}

+ (void)setUpTimeField:(NSTextField *)timeOfDay dateField:(NSTextField *)timeDate completions:(NSPopUpButton *)timeDateCompletions dateFieldEditor:(PSDateFieldEditor **)dateFieldEditor;

+ (void)updateDateField:(NSTextField *)timeDate completions:(NSPopUpButton *)timeDateCompletions fieldEditor:(PSDateFieldEditor **)dateFieldEditor;

@end
