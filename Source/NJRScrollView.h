//
//  NJRScrollView.h
//  HostLauncher
//
//  Created by nicholas on Tue Oct 30 2001.
//  Copyright (c) 2001 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRScrollView : NSScrollView {
    BOOL shouldDrawFocusRing;
    NSResponder *lastResp;
}

@end