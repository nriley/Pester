//
//  PSTimer.h
//  Pester
//
//  Created by Nicholas Riley on Sun Jan 05 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PSTimer : NSObject {
    BOOL isValid;
    BOOL repeats;
    BOOL isWakeUp;
    NSDate *fireDate;
    NSTimeInterval timeInterval;
    NSInvocation *invocation;
    id userInfo;
}

+ (void)setUp;

// partial emulation of Mac OS X 10.1 NSTimer interface
// + (PSTimer *)timerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo;
// + (PSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti invocation:(NSInvocation *)invocation repeats:(BOOL)yesOrNo;

// + (PSTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo;
+ (PSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)yesOrNo;

// - (void)fire;

- (NSDate *)fireDate;

// - (NSTimeInterval)timeInterval; // NSTimer’s version returns 0 once timer is scheduled

- (void)invalidate;
- (BOOL)isValid;

- (id)userInfo;

// other methods

- (BOOL)isWakeUp;
- (void)setWakeUp:(BOOL)doWake;

- (NSComparisonResult)compare:(PSTimer *)other;

@end
