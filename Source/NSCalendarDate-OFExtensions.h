// Copyright 1997-2002 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// http://www.omnigroup.com/DeveloperResources/OmniSourceLicense.html.
//
// $Header: /Network/Source/CVS/OmniGroup/Frameworks/OmniFoundation/OpenStepExtensions.subproj/NSCalendarDate-OFExtensions.h,v 1.12 2002/03/09 01:54:02 kc Exp $

#import <Foundation/NSCalendarDate.h>

@interface NSCalendarDate (OFExtensions)
- (void)setToUnixDateFormat;

- (NSCalendarDate *)safeReferenceDate;
- (NSCalendarDate *)firstDayOfMonth;
- (NSCalendarDate *)lastDayOfMonth;
- (NSInteger)numberOfDaysInMonth;
- (NSInteger)weekOfMonth;
    // Returns 1 through 6. Weeks are Sunday-Saturday.
- (BOOL)isInSameWeekAsDate:(NSCalendarDate *)otherDate;

@end
