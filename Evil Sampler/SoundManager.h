//
//  SoundManager.h
//  Evil Sampler
//
//  Created by david oneill on 2/17/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SoundManager : NSObject
@property BOOL running;

/*
 SoundManager uses AUSampler
 -audioFiles an array of file paths which must be in a directory named "Sounds" (not folder reference) located in the Application bundle, NSDocumentDirectory, or NSDownloadsDirectory.
 https://developer.apple.com/library/ios/technotes/tn2283/_index.html
 
 Load an array of file paths,  then access them using their index in the array
 */


@property NSArray *audioFiles;
+(SoundManager *)sharedInstance;
-(void)changeFile:(NSString *)file atIndex:(int)audioFileIndex;

-(void)play:(int)audioFileIndex withVolume:(float)volume;//volume 0.0 -> 1.0
-(void)stop:(int)audioFileIndex;


/* for monotoring volume pre and post mixer */
-(float)decibles:(int)audioFileIndex;
-(float)deciblesHold:(int)audioFileIndex;
-(float)deciblesMix;
-(float)deciblesMixHold;

@end
