/*
 *  NDAppleScriptObject.h
 *  NDAppleScriptObjectProject
 *
 *  Created by nathan on Thu Nov 29 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "NDAppleScriptObject_Protocols.h"

@interface NDAppleScriptObject : NSObject <NDAppleScriptObjectSendEvent, NDAppleScriptObjectActive>
{
    @private
    OSAID compiledScriptID, resultingValueID;
    NDAppleScriptObject	* contextAppleScriptObject;
    id<NDAppleScriptObjectSendEvent>	sendAppleEventTarget;
    id<NDAppleScriptObjectActive>	activeTarget;
    ComponentInstance			osaComponent;

    long										executionModeFlags;
}

+ (id)compileExecuteString:(NSString *) aString;
+ (Component)findNextComponent;

+ (id)appleScriptObjectWithString:(NSString *) aString;
+ (id)appleScriptObjectWithData:(NSData *) aData;
+ (id)appleScriptObjectWithContentsOfFile:(NSString *) aPath;
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *) aURL;

- (id)initWithString:(NSString *)aString modeFlags:(long)aModeFlags;
- (id)initWithContentsOfFile:(NSString *)aPath;
- (id)initWithContentsOfFile:(NSString *)aPath component:(Component)aComponent;
- (id)initWithContentsOfURL:(NSURL *)anURL;
- (id)initWithContentsOfURL:(NSURL *)aURL component:(Component)aComponent;
- (id)initWithData:(NSData *)aDesc;

- (id)initWithString:(NSString *)aString modeFlags:(long)aModeFlags component:(Component)aComponent;
- (id)initWithData:(NSData *)aData component:(Component)aComponent;

- (NSData *)data;

- (BOOL)execute;
- (BOOL)executeOpen:(NSArray *)aParameters;
- (BOOL)executeEvent:(NSAppleEventDescriptor *)anEvent;

- (NSArray *)arrayOfEventIdentifier;
- (BOOL)respondsToEventClass:(AEEventClass)aEventClass eventID:(AEEventID)aEventID;

- (NSAppleEventDescriptor *)resultAppleEventDescriptor;
- (id)resultObject;
- (id)resultData;
- (NSString *)resultAsString;

    //- (void)setContextAppleScriptObject:(NDAppleScriptObject *)aAppleScriptObject;		// NOT FUNCTIONING YET
- (long)executionModeFlags;
- (void)setExecutionModeFlags:(long)aModeFlags;

- (void)setDefaultTarget:(NSAppleEventDescriptor *)aDefaultTarget;
- (void)setDefaultTargetAsCreator:(OSType)aCreator;
- (void)setFinderAsDefaultTarget;

- (void)setAppleEventSendTarget:(id)aTarget;
- (id)appleEventSendTarget;
- (void)setActiveTarget:(id)aTarget;
- (id)activeTarget;

- (NSAppleEventDescriptor *)targetNoProcess;

- (BOOL)writeToURL:(NSURL *)aURL;
- (BOOL)writeToURL:(NSURL *)aURL Id:(short)anID;
- (BOOL)writeToFile:(NSString *)aPath;
- (BOOL)writeToFile:(NSString *)aPath Id:(short)anID;

@end
