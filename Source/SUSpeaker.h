//
//  SUSpeaker.h
//  SpeechTest
//
//  Created by raf on Sun Jan 28 2001.
//  Copyright (c) 2000 Raphael Sebbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@interface SUSpeaker : NSObject 
{
    SpeechChannel _speechChannel;
    id _delegate;
    NSPort *_port;
    
    BOOL _usePort;
    unsigned int _reserved1;
    unsigned int _reserved2;
}

+(NSArray*) voiceNames;
+ (NSString *)defaultVoice;

-(void) setPitch:(float)pitch;
-(void) setVoice:(int)index;
-(void) speakText:(NSString*)text;
-(void) stopSpeaking;

-(void) setDelegate:(id)delegate;
-(id) delegate;

@end


@interface NSObject (SUSpeakerDelegate)
-(void) didFinishSpeaking:(SUSpeaker*)speaker;
-(void) willSpeakWord:(SUSpeaker*)speaker at:(int)where length:(int)length;
@end