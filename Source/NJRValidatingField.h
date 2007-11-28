//
//  NJRValidatingField.h
//  Pester
//
//  Created by Nicholas Riley on 11/27/07.
//  Copyright 2007 Nicholas Riley. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NJRValidatingField : NSTextField {

}

- (void)handleDidFailToFormatString:(NSString *)string errorDescription:(NSString *)error label:(NSString *)label;

@end
