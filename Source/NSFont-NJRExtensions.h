//
//  NSFont-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on Sun Mar 30 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <Carbon/Carbon.h>

@interface NSFont (NJRExtensions)

+ (NSFont *)themeFont:(ThemeFontID)fontID;

@end
