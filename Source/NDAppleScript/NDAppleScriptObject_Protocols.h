/*
 *  NDAppleScriptObject_Protocols.h
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Sat Feb 16 2002.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@protocol NDAppleScriptObjectSendEvent <NSObject>
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)theAppleEventDescriptor sendMode:(AESendMode)aSendMode sendPriority:(AESendPriority)aSendPriority timeOutInTicks:(long)aTimeOutInTicks idleProc:(AEIdleUPP)anIdleProc filterProc:(AEFilterUPP)aFilterProc;
@end

@protocol NDAppleScriptObjectActive <NSObject>
- (BOOL)appleScriptActive;
@end

