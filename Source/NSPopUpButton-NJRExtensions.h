//
//  NSPopUpButton-NJRExtensions.h
//  Pester
//
//  Created by Nicholas Riley on 7/31/13.
//
//

#import <Cocoa/Cocoa.h>

@interface NSPopUpButton (NJRExtensions)

- (Class)NJR_classFromRepresentedObjectOfSelectedItem;

- (NSMenuItem *)NJR_itemWithRepresentedObjectNameOfClass:(Class)cls;

- (void)NJR_selectItemWithRepresentedObjectNameOfClass:(Class)cls;

@end
