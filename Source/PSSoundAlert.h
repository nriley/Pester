//
//  PSSoundAlert.h
//  Pester
//
//  Created by Nicholas Riley on 9/28/15.
//
//

#import "PSMediaAlert.h"

@class BDAlias;

@interface PSSoundAlert : PSMediaAlert <NSSoundDelegate> {
    PSAlarm *alarm;
    BDAlias *alias;
    NSSound *sound;
    unsigned short repetitionsRemaining;
}

+ (PSSoundAlert *)alertWithSoundFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;

- (id)initWithSoundFileAlias:(BDAlias *)anAlias repetitions:(unsigned int) numReps;

- (BDAlias *)soundFileAlias;

@end
