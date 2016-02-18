//
//  DMixer.m
//  Evil Sampler
//
//  Created by david oneill on 2/17/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUnit.h"



@implementation DMixer


-(id)init{
    return [super initWithSubType:kAudioUnitSubType_MultiChannelMixer];
}

-(void)setVolume:(AudioUnitParameterValue)volume channel:(int)channel{
    AudioUnitSetParameter (self.unit,kMultiChannelMixerParam_Volume,kAudioUnitScope_Input,channel,volume,0);
}
-(AudioUnitParameterValue)volumeForChannel:(int)channel{
    AudioUnitParameterValue vol;
    AudioUnitGetParameter(self.unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, channel, &vol);
    return vol;
}
-(void)setOutputVolume:(AudioUnitParameterValue)outputVolume{
    AudioUnitSetParameter (self.unit,kMultiChannelMixerParam_Volume,kAudioUnitScope_Output,0,outputVolume,0);
}
-(AudioUnitParameterValue)outputVolume{
    AudioUnitParameterValue vol;
    AudioUnitGetParameter(self.unit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, &vol);
    return vol;
}
-(AudioUnitParameterValue)preAveragePower:(int)element{
    AudioUnitParameterValue decibles;
    AudioUnitGetParameter(self.unit, kMultiChannelMixerParam_PreAveragePower, kAudioUnitScope_Input, element, &decibles);
    return decToMag(decibles);
}
-(AudioUnitParameterValue)prePeakHoldLevel:(int)element{
    AudioUnitParameterValue decibles;
    AudioUnitGetParameter(self.unit, kMultiChannelMixerParam_PrePeakHoldLevel, kAudioUnitScope_Input, element, &decibles);
    return decToMag(decibles);
//    double mag = pow (10, (0.05 * decibles));
}
-(AudioUnitParameterValue)postAveragePower{
    AudioUnitParameterValue decibles;
    AudioUnitGetParameter(self.unit, kMultiChannelMixerParam_PostAveragePower, kAudioUnitScope_Output, 0, &decibles);
    return decToMag(decibles);
}
-(AudioUnitParameterValue)postPeakHoldLevel{
    AudioUnitParameterValue decibles;
    AudioUnitGetParameter(self.unit, kMultiChannelMixerParam_PostPeakHoldLevel, kAudioUnitScope_Output, 0, &decibles);
    return decToMag(decibles);
}
static AudioUnitParameterValue decToMag(AudioUnitParameterValue decibles){
    return pow (10, (0.05 * decibles));
}
-(void)setMeteringModeEnabled:(BOOL)meteringModeEnabled{
    UInt32 meteringMode = meteringModeEnabled;
    AudioUnitSetProperty(self.unit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Input, 0, &meteringMode, sizeof(meteringMode));
    AudioUnitSetProperty(self.unit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Output, 0, &meteringMode, sizeof(meteringMode));
}
-(BOOL)meteringModeEnabled{
    
    UInt32 meteringModeEnabled, propSize = sizeof(UInt32);
    AudioUnitGetProperty(self.unit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Input, 0, &meteringModeEnabled, &propSize);
    return meteringModeEnabled;
}
-(int)channelCount{
    UInt32 channelCount;
    UInt32 propSize = sizeof(UInt32);
    AudioUnitGetProperty(self.unit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &channelCount, &propSize);
    return channelCount;
}
-(void)setChannelCount:(int)channelCount{
    AudioUnitSetProperty(self.unit , kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &channelCount, sizeof(channelCount));
}

-(void)clearInputs{
    AudioUnitConnection connection = {0};
    connection.sourceAudioUnit = NULL;
    connection.sourceOutputNumber = 0;
    for (int i = 0; i < self.channelCount; i++) {
        connection.destInputNumber = i;
        AudioUnitSetProperty(self.unit, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 0, &connection, sizeof(connection));
    }
}
@end

