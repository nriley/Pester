//
//  PSBeepAlert.h
//  Pester
//
//  Created by Nicholas Riley on Sat Oct 26 2002.
//  Copyright (c) 2002 Nicholas Riley. All rights reserved.
//

#import "PSAlert.h"

@interface PSBeepAlert : PSAlert {
    PSAlarm *alarm;
    unsigned short repetitions;
    unsigned short repetitionsRemaining;
}

+ (PSBeepAlert *)alertWithRepetitions:(unsigned short)numReps;
- (id)initWithRepetitions:(unsigned short)numReps;

- (unsigned short)repetitions;

@end
