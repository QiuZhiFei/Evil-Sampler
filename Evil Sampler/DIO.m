//
//  DIO.m
//  Evil Sampler
//
//  Created by david oneill on 2/17/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUnit.h"

@implementation DIO

-(id)init{
    return [super initWithSubType:kAudioUnitSubType_RemoteIO];
}
-(void)setRunning:(BOOL)running{
    if (running == [self running]) {
        return;
    }
    if (running) {
        AudioOutputUnitStart(self.unit);
    }
    else{
        AudioOutputUnitStop(self.unit);
    }
}
-(BOOL)running{
    UInt32 isRunning;
    UInt32 propSize = sizeof(UInt32);
    AudioUnitGetProperty(self.unit, kAudioOutputUnitProperty_IsRunning, kAudioUnitScope_Global, 0, &isRunning, &propSize);
    return isRunning;
}

@end
