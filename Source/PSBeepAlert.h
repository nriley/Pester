//
//  PSBeepAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSMediaAlert.h"

@interface PSBeepAlert : PSMediaAlert {
    PSAlarm *alarm;
    unsigned short repetitionsRemaining;
}

+ (PSBeepAlert *)alertWithRepetitions:(unsigned short)numReps;

@end
