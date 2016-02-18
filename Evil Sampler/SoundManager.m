//
//  SoundManager.m
//  Evil Sampler
//
//  Created by david oneill on 2/17/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import "SoundManager.h"
#import "DUnit.h"
#import <AVFoundation/AVFoundation.h>


@interface SoundManager ()
@property DIO                   *io;
@property DMixer                *mixer;
@property NSArray <DSampler *>  *samplers;
@end

@implementation SoundManager{
    NSArray *_audioFiles;
}
+(SoundManager *)sharedInstance{
    static dispatch_once_t pred;
    static SoundManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[SoundManager alloc] init];
        sharedInstance.running = 1;
        
    });
    return sharedInstance;
}
-(instancetype)init{
    self = [super init];
    if (self) {
        [self setUpAudioSession];
        [self setUpAudioUnits];
        _audioFiles = @[];
    }
    return self;
}
-(void)setUpAudioSession{
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setPreferredIOBufferDuration:0.01 error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    [audioSession setActive:1 error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
}
-(void)setUpAudioUnits{
    if (!self.io) {
        self.io = [[DIO alloc]init];
        self.mixer = [[DMixer alloc]init];
        [self.mixer connectTo:self.io channel:0];
        self.mixer.meteringModeEnabled = 1;
        [self.mixer initialize];
        [self.io initialize];
    }
}

//Decided to do a sampler for each file instead of one sampler to enable metering for Snazzy UI
-(void)setAudioFiles:(NSArray *)audioFiles{
    int index = 0;
    
    //Make sure mixer has enough available channels before making connections
    self.mixer.channelCount = (int)MAX(self.samplers.count,(int)audioFiles.count);
    NSMutableArray *samplers = [[NSMutableArray alloc]initWithArray:self.samplers];
    
    //Reuse existing samplers, create if needed.
    for (NSString *file in audioFiles) {
        DSampler *sampler = NULL;
        if (index < samplers.count) {
            sampler = samplers[index];
        }
        else{
            sampler = [[DSampler alloc]init];
            [sampler initialize];
            [sampler connectTo:self.mixer channel:index];
            [self.mixer setVolume:1 channel:index];
            [samplers addObject:sampler];
        }
        
        [sampler setPresetWithPaths:@[file]];
        index++;
    }
    
    //Remove unused samplers from audio chain
    while (samplers.count > audioFiles.count) {
        DSampler *sampler = samplers.lastObject;
        [self.mixer disconnectInput:(int)samplers.count - 1];
        [sampler uninitialize];
        [sampler dispose];
        [samplers removeLastObject];
    }
    
    
    
    self.samplers = samplers;
    self.mixer.channelCount = (int)MAX(8,(int)self.samplers.count);
    self.mixer.meteringModeEnabled = 1;
    _audioFiles = audioFiles;
    
}
-(void)changeFile:(NSString *)file atIndex:(int)audioFileIndex{
    if (audioFileIndex < 0 || audioFileIndex >= self.samplers.count) {
        NSLog(@"index out of range");
        return;
    }
    
    NSMutableArray *audioFiles = _audioFiles.mutableCopy;
    [audioFiles replaceObjectAtIndex:audioFileIndex withObject:file];
    _audioFiles = audioFiles;
    
    DSampler *sampler = _samplers[audioFileIndex];
    [sampler setPresetWithPaths:@[file]];
}
-(NSArray *)audioFiles{
    return _audioFiles;
}
-(void)play:(int)audioFileIndex withVolume:(float)volume{
    if (audioFileIndex < 0 || audioFileIndex >= self.samplers.count) {
        NSLog(@"index out of range");
        return;
    }
    [self.samplers[audioFileIndex] noteOn:0 volume:volume];
}
-(void)stop:(int)audioFileIndex{
    if (audioFileIndex < 0 || audioFileIndex >= self.samplers.count) {
        NSLog(@"index out of range");
        return;
    }
    [self.samplers[audioFileIndex] noteOff:0];
}
-(float)decibles:(int)audioFileIndex{
    return [self.mixer preAveragePower:audioFileIndex];
}
-(float)deciblesHold:(int)audioFileIndex{
    return [self.mixer prePeakHoldLevel:audioFileIndex];
}
-(float)deciblesMix{
    return [self.mixer postAveragePower];
}
-(float)deciblesMixHold{
    return [self.mixer postPeakHoldLevel];
}

-(void)setRunning:(BOOL)running{
    [self setUpAudioSession];
    [self setUpAudioUnits];
    self.io.running = running;
}
-(BOOL)running{
    return self.io == NULL ? 0 : self.io.running;
}
@end
