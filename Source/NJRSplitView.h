//
//  NJRSplitView.h
//  Pester
//
//  Created by Nicholas Riley on Thu Feb 20 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRSplitView : NSSplitView {
    float expandedWidth;
}

- (void)collapseSubview:(NSView *)subview;
- (void)expandSubview:(NSView *)subview;

@end
