
//  Created by David O'Neill on 2/17/16.
//  Copyright (c) 2016 David O'Neill. All rights reserved.

#import "DUnit.h"


@implementation DUnit
-(id)initWithGraph:(AUGraph)graph{
    return [super init];
}
-(id)initWithSubType:(OSType)subType{
    self = [super init];
    if (self){
        AudioComponentDescription desc = AudioUnitGetDecriptionFromSubtype(subType);
        AudioComponent ioComponent = AudioComponentFindNext(NULL, &desc);
        AudioComponentInstanceNew(ioComponent, &_unit);
    }
    return self;
}

-(void)connectTo:(DUnit *)dUnit channel:(int)element{
    UInt32 inSourceOutputNumber = 0;
    AudioUnitConnection connection;
    connection.destInputNumber = element;
    connection.sourceAudioUnit = self.unit;
    connection.sourceOutputNumber = inSourceOutputNumber;
    OSStatus error = AudioUnitSetProperty(dUnit.unit, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 0, &connection, sizeof(connection));
    if (error) {
        printf("connect er %i %i\n",__LINE__,error);
    }
}
-(void)disconnectInput:(int)channel{
    AudioUnitConnection connection = {0};
    connection.sourceAudioUnit = NULL;
    connection.sourceOutputNumber = 0;
    connection.destInputNumber = channel;
    AudioUnitSetProperty(self.unit, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 0, &connection, sizeof(connection));
}
-(void)setAsbdIn:(ASBD)asbdIn{
    AudioUnitSetProperty(self.unit,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Input,0,&asbdIn,sizeof(ASBD));
}

-(ASBD)asbdIn{
    ASBD asbdIn;
    UInt32 sizeASBD = sizeof(ASBD);
    AudioUnitGetProperty(self.unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &asbdIn, &sizeASBD);
    return asbdIn;
}
-(void)setAsbdOut:(ASBD)asbdOut{
    AudioUnitSetProperty(self.unit,kAudioUnitProperty_StreamFormat,kAudioUnitScope_Output,0,&asbdOut,sizeof(ASBD));
}
-(ASBD)asbdOut{
    ASBD asbdOut;
    UInt32 sizeASBD = sizeof(ASBD);
    AudioUnitGetProperty(self.unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbdOut, &sizeASBD);
    return asbdOut;
}
-(OSStatus)initialize{
    OSStatus status = AudioUnitInitialize(self.unit);
    if (status) {
        printf("initialize er %i %i\n",__LINE__,status);
    }
    return status;
}
-(OSStatus)uninitialize{
    OSStatus status = AudioUnitUninitialize(self.unit);
    return status;
}
-(void)dispose{
    AudioComponentInstanceDispose(self.unit);
}

-(void)setParameter:(OSType)parameter value:(AudioUnitParameterValue)value{
    AudioUnitSetParameter (_unit,parameter,kAudioUnitScope_Global,0,value,0);
}
-(AudioUnitParameterValue)getParameter:(OSType)parameterID{
    AudioUnitParameterValue levelOut;
    AudioUnitGetParameter(_unit,parameterID,kAudioUnitScope_Global,0,&levelOut);
    return levelOut;
}

@end











AudioComponentDescription AudioUnitGetDecriptionFromSubtype(OSType subType){
    AudioComponentDescription       descript;
    descript.componentFlags = 0;
    descript.componentFlagsMask = 0;
    descript.componentManufacturer = kAudioUnitManufacturer_Apple;
    descript.componentSubType =  subType;
    
    if (subType == kAudioUnitSubType_MultiChannelMixer){
        descript.componentType = kAudioUnitType_Mixer;
    }
    else if (
             subType == kAudioUnitSubType_PeakLimiter ||
             subType == kAudioUnitSubType_DynamicsProcessor ||
             subType == kAudioUnitSubType_Reverb2 ||
             subType == kAudioUnitSubType_LowPassFilter ||
             subType == kAudioUnitSubType_HighPassFilter ||
             subType == kAudioUnitSubType_BandPassFilter ||
             subType == kAudioUnitSubType_HighShelfFilter ||
             subType == kAudioUnitSubType_LowShelfFilter ||
             subType == kAudioUnitSubType_ParametricEQ ||
             subType == kAudioUnitSubType_Distortion ||
             subType == kAudioUnitSubType_NBandEQ
             )
    {
        descript.componentType = kAudioUnitType_Effect;
    }
    else if  (
              subType == kAudioUnitSubType_AUConverter ||
              subType == kAudioUnitSubType_Varispeed	||
              subType == kAudioUnitSubType_AUiPodTime ||
              subType == kAudioUnitSubType_AUiPodTimeOther ||
              subType == kAudioUnitSubType_NewTimePitch)
    {
        descript.componentType = kAudioUnitType_FormatConverter;
    }
    
    else if (subType == kAudioUnitSubType_Sampler) {
        descript.componentType = kAudioUnitType_MusicDevice;
    }
    
    else if (subType == kAudioUnitSubType_AudioFilePlayer){
        descript.componentType = kAudioUnitType_Generator;
    }
    
    else if (kAudioUnitSubType_RemoteIO) {
        descript.componentType = kAudioUnitType_Output;
    }
    
    return descript;
}


ASBD asbdWithInfo(Boolean isFloat,int numberOfChannels,Boolean interleavedIfStereo,double sampleRate){
    ASBD asbd = {0};
    int sampleSize          = isFloat ? sizeof(float) : sizeof(SInt16);
    asbd.mChannelsPerFrame  = (numberOfChannels == 1) ? 1 : 2;
    asbd.mBitsPerChannel    = 8 * sampleSize;
    asbd.mFramesPerPacket   = 1;
    asbd.mSampleRate        = sampleRate;
    asbd.mBytesPerFrame     = interleavedIfStereo ? sampleSize * asbd.mChannelsPerFrame : sampleSize;
    asbd.mBytesPerPacket    = asbd.mBytesPerFrame;
    asbd.mReserved          = 0;
    asbd.mFormatID          = kAudioFormatLinearPCM;
    if (isFloat) {
        asbd.mFormatFlags = kAudioFormatFlagIsFloat;
        if (interleavedIfStereo) {
            if (numberOfChannels == 1) {
                asbd.mFormatFlags = asbd.mFormatFlags | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
            }
        }
        else{
            asbd.mFormatFlags = asbd.mFormatFlags | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsPacked ;
        }
    }
    else{
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
        if (!interleavedIfStereo) {
            if (numberOfChannels > 1) {
                asbd.mFormatFlags = asbd.mFormatFlags | kAudioFormatFlagIsNonInterleaved;
            }
            
        }
    }
    return asbd;
}
ASBD asbdAAC(int channels){
    ASBD desc = {0};
    desc.mFormatID = kAudioFormatMPEG4AAC;
    desc.mChannelsPerFrame = channels;
    
    UInt32 propSize = sizeof(ASBD);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &desc);
    return desc;
}














