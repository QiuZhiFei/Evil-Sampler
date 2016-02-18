

//  Created by David O'Neill on 2/17/16.
//  Copyright (c) 2016 David O'Neill. All rights reserved.

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


/*
    DUnit is a class for wrapping an audio unit in Objective-C. A chain of DUnits must have a DIO as the last link.  Audio is started and stoped by setting DIO.running.
 
 
*/


typedef AudioStreamBasicDescription ASBD;



@interface DUnit : NSObject
@property AudioComponentInstance unit;
@property ASBD asbdIn;
@property ASBD asbdOut;
-(id)initWithSubType:(OSType)subType;
-(void)connectTo:(DUnit *)dUnit channel:(int)element;
-(void)disconnectInput:(int)channel;
-(OSStatus)initialize;
-(OSStatus)uninitialize;
-(void)dispose;
-(void)setParameter:(OSType)parameter value:(AudioUnitParameterValue)value;
-(AudioUnitParameterValue)getParameter:(OSType)parameterID;
@end



@interface DIO : DUnit
@property (nonatomic) BOOL running;
@end




@interface DMixer : DUnit
@property BOOL  meteringModeEnabled;
@property AudioUnitParameterValue outputVolume;
@property int channelCount;
-(void)setVolume:(AudioUnitParameterValue)volume channel:(int)channel;
-(AudioUnitParameterValue)volumeForChannel:(int)channel;
-(AudioUnitParameterValue)preAveragePower:(int)element;
-(AudioUnitParameterValue)prePeakHoldLevel:(int)element;
-(AudioUnitParameterValue)postAveragePower;
-(AudioUnitParameterValue)postPeakHoldLevel;
-(void)clearInputs;
@end




/*
 Apple's AUSampler expects a very specific plist for setting up the samples. You can immport your own plist created in the AULab Mac app.  Or instantiate using initWithPaths;

 -initWithPaths Takes an array of file paths which must be in a directory named "Sounds" (not folder reference) located in the Application bundle, NSDocumentDirectory, or NSDownloadsDirectory.
 https://developer.apple.com/library/ios/technotes/tn2283/_index.html
 
 setPresetWithPaths:(NSArray *)audioFilePaths will link each audio file with it's index in the audioFilePaths array.
 eg.
 NSArray *filepaths = @[@"Sounds/a.wav",@"Sounds/b.wav"];
 [sampler setPresetWithPaths:filePaths];
 
 After audio unit chain is running you can trigger 
 a.wav by calling [sampler noteOn:0 volume:1] and b.wav by calling [sampler noteOn:1 volume:1]
 */

@interface DSampler : DUnit
@property (nonatomic) NSDictionary *preset;
-(void)setPresetWithPaths:(NSArray *)audioFilePaths;
-(OSStatus) createPresetFromSamples: (NSArray *)urlArray;
-(void)noteOn:(int)note volume:(float)volume; // volume = 0.0 -> 1.0
-(void)noteOff:(int)note;
@end


AudioComponentDescription AudioUnitGetDecriptionFromSubtype(OSType subType);
ASBD asbdWithInfo(Boolean isFloat,int numberOfChannels,Boolean interleavedIfStereo,double sampleRate);
ASBD asbdAAC(int channels);






