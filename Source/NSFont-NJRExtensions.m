//
//  NSFont-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on Sun Mar 30 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NSFont-NJRExtensions.h"

@implementation NSFont (NJRExtensions)

+ (NSFont *)themeFont:(ThemeFontID)fontID;
{
    NSFont *themeFont = nil;
    Str255 pstrFontName;
    SInt16 fontSize = 0;
    OSStatus status;
    // can't simulate algorithmic styles in Cocoa in any case, so here's hoping nothing will be passed back - XXX guess this should at least accommodate the bold system font, but we don't need it
    status = GetThemeFont(fontID, smSystemScript, pstrFontName, &fontSize, NULL);

    if (status == noErr) {
        NSString *fontName = (NSString *)CFStringCreateWithPascalString(NULL, pstrFontName, CFStringGetSystemEncoding());
        themeFont = [NSFont fontWithName: fontName size: fontSize];
        [fontName release];
    }
    if (themeFont == nil) {
        themeFont = [NSFont systemFontOfSize: fontSize == 0 ? [NSFont systemFontSize] : fontSize];
    }
    return themeFont;
}

@end
