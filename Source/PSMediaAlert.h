//
//  PSMediaAlert.h
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 08 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "PSAlert.h"


@interface PSMediaAlert : PSAlert {
    unsigned short repetitions;
    float outputVolume;
}

- (id)initWithRepetitions:(unsigned short)numReps;

- (unsigned short)repetitions;
- (float)outputVolume;
- (void)setOutputVolume:(float)volume;

@end
