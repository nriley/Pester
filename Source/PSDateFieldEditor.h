//
//  PSDateFieldEditor.h
//  Pester
//
//  Created by Nicholas Riley on 3/1/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PSDateFieldEditor : NSTextView {
    NSArray *allCompletions;
}

- (id)initWithCompletions:(NSArray *)dateCompletions;

@end
