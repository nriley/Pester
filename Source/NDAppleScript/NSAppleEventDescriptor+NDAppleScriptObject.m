/*
 *  NSAppleEventDescriptor+NDAppleScriptObject.m
 *  AppleScriptObjectProject
 *
 *  Created by Nathan Day on Fri Dec 14 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "NSURL+NDCarbonUtilities.h"

@implementation NSAppleEventDescriptor (NDAppleScriptObject)

/*
 * + appleEventDescriptorWithString:
 */

+ (NSAppleEventDescriptor *)appleEventDescriptorWithString:(NSString *)aString
{
    return [self descriptorWithDescriptorType:typeChar data:[aString dataUsingEncoding:NSMacOSRomanStringEncoding]];
}

/*
 * + aliasListDescriptorWithArray:
 */
+ (NSAppleEventDescriptor *)aliasListDescriptorWithArray:(NSArray *)aArray
{
    NSAppleEventDescriptor	* theEventList = nil;
    unsigned int				theIndex,
        theNumOfParam;

    theNumOfParam = [aArray count];

    if( theNumOfParam > 0)
       {
        theEventList = [self listDescriptor];

        for( theIndex = 0; theIndex < theNumOfParam; theIndex++ )
           {
            id				theObject;
            theObject = [aArray objectAtIndex:theIndex];

            if( [theObject isKindOfClass:[NSString class]] )
                theObject = [NSURL fileURLWithPath:theObject];

            [theEventList insertDescriptor:[self aliasDescriptorWithURL:theObject] atIndex:theIndex+1];
           }
       }

    return theEventList;
}

/*
 * + appleEventDescriptorWithURL:
 */
+ (NSAppleEventDescriptor *)appleEventDescriptorWithURL:(NSURL *)aURL
{
    return [self descriptorWithDescriptorType:typeFileURL data:[NSData dataWithBytes:(void *)aURL length:sizeof(NSURL)]];
}

/*
 * + aliasDescriptorWithURL:
 */
+ (NSAppleEventDescriptor *)aliasDescriptorWithURL:(NSURL *)aURL
{
    AliasHandle						theAliasHandle;
    FSRef								theReference;
    NSAppleEventDescriptor		* theAppleEventDescriptor = nil;

    if( [aURL getFSRef:&theReference] == YES && FSNewAliasMinimal( &theReference, &theAliasHandle ) == noErr )
       {
        HLock((Handle)theAliasHandle);
        theAppleEventDescriptor = [self descriptorWithDescriptorType:typeAlias data:[NSData dataWithBytes:*theAliasHandle length:GetHandleSize((Handle) theAliasHandle)]];
        HUnlock((Handle)theAliasHandle);
        DisposeHandle((Handle)theAliasHandle);
       }

    return theAppleEventDescriptor;
}

// typeBoolean
+ (NSAppleEventDescriptor *)appleEventDescriptorWithBOOL:(BOOL)aValue
{
    return [self descriptorWithDescriptorType:typeBoolean data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeTrue
+ (NSAppleEventDescriptor *)trueBoolDescriptor
{
    return [self descriptorWithDescriptorType:typeTrue data:[NSData data]];
}
// typeFalse
+ (NSAppleEventDescriptor *)falseBoolDescriptor
{
    return [self descriptorWithDescriptorType:typeFalse data:[NSData data]];
}
// typeShortInteger
+ (NSAppleEventDescriptor *)appleEventDescriptorWithShort:(short int)aValue
{
    return [self descriptorWithDescriptorType:typeShortInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeLongInteger
+ (NSAppleEventDescriptor *)appleEventDescriptorWithLong:(long int)aValue
{
    return [self descriptorWithDescriptorType:typeLongInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeInteger
+ (NSAppleEventDescriptor *)appleEventDescriptorWithInt:(int)aValue
{
    return [self descriptorWithDescriptorType:typeInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeShortFloat
+ (NSAppleEventDescriptor *)appleEventDescriptorWithFloat:(float)aValue
{
    return [self descriptorWithDescriptorType:typeShortFloat data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeLongFloat
+ (NSAppleEventDescriptor *)appleEventDescriptorWithDouble:(double)aValue
{
    return [self descriptorWithDescriptorType:typeLongFloat data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeMagnitude
+ (NSAppleEventDescriptor *)appleEventDescriptorWithUnsignedInt:(unsigned int)aValue
{
    return [self descriptorWithDescriptorType:typeMagnitude data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}

/*
 * targetProcessSerialNumber
 */
- (ProcessSerialNumber)targetProcessSerialNumber
{
    NSAppleEventDescriptor	* theTarget;
    ProcessSerialNumber		theProcessSerialNumber = { 0, 0 };

    theTarget = [self attributeDescriptorForKeyword:keyAddressAttr];

    if( theTarget )
       {
        if( [theTarget descriptorType] != typeProcessSerialNumber )
            theTarget = [theTarget coerceToDescriptorType:typeProcessSerialNumber];

        [[theTarget data] getBytes:&theProcessSerialNumber length:sizeof(ProcessSerialNumber)];
       }
    return theProcessSerialNumber;
}

/*
 * targetCreator
 */
- (OSType)targetCreator
{
    NSAppleEventDescriptor	* theTarget;
    OSType						theCreator = 0;

    theTarget = [self attributeDescriptorForKeyword:keyAddressAttr];

    if( theTarget )
       {
        if( [theTarget descriptorType] != typeApplSignature )
            theTarget = [theTarget coerceToDescriptorType:typeApplSignature];

        [[theTarget data] getBytes:&theCreator length:sizeof(OSType)];
       }
    return theCreator;
}

/*
 * isTargetCurrentProcess
 */
- (BOOL)isTargetCurrentProcess
{
    ProcessSerialNumber		theProcessSerialNumber;

    theProcessSerialNumber = [self targetProcessSerialNumber];

    return theProcessSerialNumber.highLongOfPSN == 0 && theProcessSerialNumber.lowLongOfPSN == kCurrentProcess;
}

@end
