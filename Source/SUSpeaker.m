//
//  SUSpeaker.m
//  SpeechTest
//
//  Created by raf on Sun Jan 28 2001.
//  Copyright (c) 2000 Raphael Sebbe. All rights reserved.
//

#import "SUSpeaker.h"
#include <unistd.h>
#include <pthread.h>

void MySpeechDoneCallback(SpeechChannel chan,SInt32 refCon);
void MySpeechWordCallback (SpeechChannel chan, SInt32 refCon, UInt32 wordPos, 
    UInt16 wordLen);

@interface SUSpeaker (Private)
-(void) setCallbacks;
-(NSPort*) port;
-(void) setReserved1:(unsigned int)r;
-(void) setReserved2:(unsigned int)r;
-(BOOL) usesPort;
-(void) handleMessage:(unsigned)msgid;
@end


@implementation SUSpeaker

/*"Returns the voice names in the same order as expected by setVoice:."*/
+(NSArray*) voiceNames
{
    NSMutableArray *voices = [NSMutableArray arrayWithCapacity:0];
    short voiceCount;
    OSErr error = noErr;
    int voiceIndex;
    
    
    
    error = CountVoices(&voiceCount);
    
    if(error != noErr) return voices;
    //NSLog(@"hello : %d", voiceCount);
    for(voiceIndex=0; voiceIndex<voiceCount; voiceIndex++)
    {
        VoiceSpec	voiceSpec;
        VoiceDescription voiceDescription;
        
        error = GetIndVoice(voiceIndex+1, &voiceSpec);
        if(error != noErr) return voices;
        error = GetVoiceDescription( &voiceSpec, &voiceDescription, sizeof(voiceDescription));
        if(error == noErr)
        {
            NSString *voiceName = [[[NSString alloc] initWithCString:
                &(voiceDescription.name[1]) length:voiceDescription.name[0]] autorelease];
            //NSLog(voiceName);
            
            [voices addObject:voiceName];
        }
        else return voices;
    }
    return voices;
}

+ (NSString *)defaultVoice;
{
    OSStatus err = noErr;
    VoiceDescription voiceDescription;

    err = GetVoiceDescription(NULL, &voiceDescription, sizeof(voiceDescription));

    return [[[NSString alloc] initWithCString: &(voiceDescription.name[1]) length:voiceDescription.name[0]] autorelease];
}

-init
{
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [super init];

    // we have 2 options here : we use a port or we don't.
    // using a port means delegate message are invoked from the main 
    // thread (runloop in which this object is created), otherwise, those message 
    // are asynchronous.
    if(loop != nil) 
    {
        _port = [[NSPort port] retain];
        // we use a port so that the speech manager callbacks can talk to the main thread.
        // That way, we can safely access interface elements from the delegate methods
        
        [_port setDelegate:self];
        [loop addPort:_port forMode:NSDefaultRunLoopMode];
        _usePort = YES;
    }
    else _usePort = NO;
    
    NewSpeechChannel(NULL, &_speechChannel); // NULL voice is default voice
    [self setCallbacks];
    return self;
}

-(void) dealloc
{

    [_port release];
    if(_speechChannel != NULL)
    {
        DisposeSpeechChannel(_speechChannel);
    }
    
    [super dealloc];
}


/*"Sets the pitch. Pitch is given in Hertz and should be comprised between 80 and 500, depending on the voice. Note that extreme value can make you app crash..."*/ 
-(void) setPitch:(float)pitch
{
    int fixedPitch;
    
    
    pitch = (pitch-90.0)/(300.0-90.0)*(65.0 - 30.0) + 30.0;
    /* I don't know what Apple means with pitch between 30 and 65, so I convert that range to [90, 300]. I did not test frequencies correspond, though.*/
    
    fixedPitch = (int)pitch;
    
    fixedPitch = fixedPitch << 16; // fixed point
    
    if(_speechChannel != NULL)
    {
        SetSpeechPitch (_speechChannel, fixedPitch);
    }
}
-(void) setVoice:(int)index
{
    VoiceSpec voice;
    OSErr error = noErr;
    
    if(_speechChannel != NULL)
    {
        DisposeSpeechChannel(_speechChannel);
        _speechChannel = NULL;
    }
    
    error = GetIndVoice(index, &voice);
    if(error == noErr)
    {
        NewSpeechChannel(&voice, &_speechChannel);
        [self setCallbacks];
    }
}
-(void) speakText:(NSString*)text
{
    //pid_t pid = getpid();
    //pthread_t t = pthread_self();
    //NSLog(@"pid : %d", t);

    if(_speechChannel != NULL && text != nil)
    {
        //finished = NO;
        SpeakText(_speechChannel, [text cString], [text length]);
        //while(!finished) ;
        //sleep(2);
    }
}
-(void) stopSpeaking
{
    if(_speechChannel != NULL)
    {
        StopSpeech(_speechChannel);
        if([_delegate respondsToSelector:@selector(didFinishSpeaking:)])
        {
            [_delegate didFinishSpeaking:self];
        }
    }
}

-(void) setDelegate:(id)delegate
{
    _delegate = delegate;
}
-(id) delegate
{
    return _delegate;
}

//--- Private ---

-(void) setCallbacks
{
    if(_speechChannel != NULL)
    {
        SetSpeechInfo(_speechChannel, soSpeechDoneCallBack, &MySpeechDoneCallback);
        SetSpeechInfo(_speechChannel, soWordCallBack, &MySpeechWordCallback);
        SetSpeechInfo(_speechChannel, soRefCon, (const void*)self);
    }
}
-(void) setReserved1:(unsigned int)r
{
    _reserved1 = r;
}
-(void) setReserved2:(unsigned int)r
{
    _reserved2 = r;
}
-(NSPort*) port
{
    return _port;
}
-(BOOL) usesPort
{
    return _usePort;
}
-(void) handleMessage:(unsigned)msgid
{
    if(msgid == 5)
    {
        if([_delegate respondsToSelector:@selector(willSpeakWord:at:length:)])
        {
            if(_reserved1 >= 0 && _reserved2 >= 0)
                [_delegate willSpeakWord:self at:_reserved1 length:_reserved2];
            else
                [_delegate willSpeakWord:self at:0 length:0];
        }
    }
    else if(msgid == 8)
    {
        if([_delegate respondsToSelector:@selector(didFinishSpeaking:)])
        {
            [_delegate didFinishSpeaking:self];
        }
    }
}
//--- NSPort delegate ---
- (void)handlePortMessage:(NSPortMessage *)portMessage
{
    int msg = [portMessage msgid];
    
    [self handleMessage:msg];
}

@end

void MySpeechDoneCallback(SpeechChannel chan,SInt32 refCon)
{
    SUSpeaker *speaker = (SUSpeaker*)refCon;
    unsigned msg = 8;
    //NSLog(@"Speech Done");
    
    if([speaker isKindOfClass:[SUSpeaker class]])
    {
        if([speaker usesPort])
        {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:[speaker port]
                receivePort:[speaker port] components:nil];
        
            [message setMsgid:msg];
            [message sendBeforeDate:nil];
            [message release];
        }
        else
        {
            // short-circuit port
            [speaker handleMessage:msg];
        }
    } 
}
void MySpeechWordCallback(SpeechChannel chan, SInt32 refCon, UInt32 wordPos,UInt16 wordLen)
{
    SUSpeaker *speaker = (SUSpeaker*)refCon;
    unsigned msg = 5;
    //pid_t pid = getpid();
    //pthread_t t = pthread_self();
    //NSLog(@"pid : %d", t);
    
    
    //NSLog(@"Word Done");
    //while(1);
    if([speaker isKindOfClass:[SUSpeaker class]])
    {
        [speaker setReserved1:wordPos];
        [speaker setReserved2:wordLen];
        
        if([speaker usesPort])
        {
            NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort:[speaker port]
                receivePort:[speaker port] components:nil];
        
            [message setMsgid:msg];
            [message sendBeforeDate:nil];
            [message release];
        }
        else 
        {
            // short-circuit port
            [speaker handleMessage:msg];
        }
    } 
}
