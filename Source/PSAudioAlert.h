//
//  PSAudioAlert.h
//  Pester
//
//  Created by Nicholas Riley on 9/21/15.
//
//

#import "PSMediaAlert.h"

@class BDAlias;
@class AVAudioEngine;

@interface PSAudioAlert : PSMediaAlert {
    BDAlias *alias;
    AVAudioEngine *audioEngine;
}

+ (PSAudioAlert *)alertWithAudioFileAlias:(BDAlias *)anAlias repetitions:(unsigned short)numReps;

- (id)initWithAudioFileAlias:(BDAlias *)anAlias repetitions:(unsigned int) numReps;

- (BDAlias *)audioFileAlias;

@end
