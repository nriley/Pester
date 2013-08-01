//
//  NSPopUpButton-NJRExtensions.m
//  Pester
//
//  Created by Nicholas Riley on 7/31/13.
//
//

#import "NSPopUpButton-NJRExtensions.h"

@implementation NSPopUpButton (NJRExtensions)

- (Class)NJR_classFromRepresentedObjectOfSelectedItem;
{
    return NSClassFromString([[self selectedItem] representedObject]);
}

- (NSMenuItem *)NJR_itemWithRepresentedObjectNameOfClass:(Class)cls;
{
    return [self itemAtIndex: [self indexOfItemWithRepresentedObject: NSStringFromClass(cls)]];
}

- (void)NJR_selectItemWithRepresentedObjectNameOfClass:(Class)cls;
{
    [self selectItemAtIndex: [self indexOfItemWithRepresentedObject: NSStringFromClass(cls)]];
}

@end
