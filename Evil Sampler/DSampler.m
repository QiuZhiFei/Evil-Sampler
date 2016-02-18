//
//  DSampler.m
//  Evil Sampler
//
//  Created by david oneill on 2/17/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DUnit.h"


#define FILEREFPREFIX @"Sample:"
#define STARTINGWAVEFORMID 268435457
#define NOTEON 144
#define NOTEOFF 128


@implementation DSampler{
    NSDictionary *_preset;
}

-(id)init{
    return [super initWithSubType:kAudioUnitSubType_Sampler];
}
-(void)setPreset:(NSDictionary *)preset{
    if (preset) {
        CFPropertyListRef presetPlist = (__bridge CFPropertyListRef)preset;
        AudioUnitSetProperty(self.unit,kAudioUnitProperty_ClassInfo,kAudioUnitScope_Global,0,&presetPlist,sizeof(presetPlist));
    }
}
-(NSDictionary *)preset{
    
    CFPropertyListRef presetPlist;
    UInt32 presetPlistSize = sizeof(CFPropertyListRef);
    AudioUnitGetProperty(self.unit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &presetPlist, &presetPlistSize);
    NSDictionary *presetDict = (__bridge NSDictionary *)presetPlist;
    CFRelease(presetPlist);
    return presetDict;
}
-(void)noteOn:(int)note volume:(float)volume{
    MusicDeviceMIDIEvent    (self.unit,NOTEON,note,volume * 127,0);
}
-(void)noteOff:(int)note{
    MusicDeviceMIDIEvent    (self.unit,NOTEOFF,note,0,0);
}

-(void)setPresetWithPaths:(NSArray *)audioFilePaths{
    self.preset = presetWithPaths(audioFilePaths);
}

/*
 
 This is a workaround for loading AUSampler's esoteric preset format dynamically.  I parsed the format of a working example and saved it as Skeleton.aupreset,  this function just fills in the required entries to get a working preset.
 */

static NSDictionary *presetWithPaths(NSArray *fileNamesInSoundsDir){
    NSURL *skeletonURL = [[NSBundle mainBundle]URLForResource:@"Skeleton" withExtension:@"aupreset"];
    NSMutableDictionary *preset = [NSMutableDictionary dictionaryWithContentsOfURL:skeletonURL];
    preset[@"Instrument"] = [preset[@"Instrument"] mutableCopy];
    NSMutableDictionary *instrument = preset[@"Instrument"];
    
    NSMutableDictionary *fileRefs = [[NSMutableDictionary alloc]init];
    NSMutableArray *zones = [[NSMutableArray alloc]init];
    
    NSMutableDictionary *duplicateCheck = [[NSMutableDictionary alloc]init];
    
    int waveformID = STARTINGWAVEFORMID;
    for (NSString *fileName in fileNamesInSoundsDir) {
        
        NSNumber *dup = [duplicateCheck objectForKey:fileName];
        NSString *waveFormKey = NULL;
        if (dup) {
            waveFormKey = [NSString stringWithFormat:@"%@%@",FILEREFPREFIX,dup];
            [zones addObject:samplerNewZone(@(zones.count), dup)];
        }
        else{
            waveFormKey = [NSString stringWithFormat:@"%@%i",FILEREFPREFIX,waveformID];
            [fileRefs setObject:fileName forKey:waveFormKey];
            [duplicateCheck setObject:@(waveformID) forKey:fileName];
            [zones addObject:samplerNewZone(@(zones.count), @(waveformID))];
            waveformID += 1;
        }
        
    }
    
    NSMutableArray *layers = instrument[@"Layers"];
    NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithDictionary:layers.firstObject];
    layer[@"Zones"] = zones;
    instrument[@"Layers"] = @[layer];
    preset[@"file-references"] = fileRefs;
    return preset;
}
-(void)dealloc{
    printf("dead sampler\n");
}
static NSDictionary *samplerNewZone(NSNumber *ID, NSNumber *waveform){
    return @{
             @"ID":             ID,
             @"enabled":        @1,
             @"loop enabled":   @0,
             @"min key":        ID,
             @"max key":        ID,
             @"root key":       ID,
             @"pitch tracking": @0,
             @"waveform":       waveform
             };
}

@end









