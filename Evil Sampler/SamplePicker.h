//
//  SamplePicker.h
//  Evil Sampler
//
//  Created by david oneill on 2/18/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SamplePicker;
@protocol SamplePickerDelegate <NSObject>
-(void)samplePicker:(SamplePicker *)samplePicker pickedSample:(NSString *)sample;
-(void)samplePickerDismissed:(SamplePicker *)samplePicker;
@end

@interface SamplePicker : UIViewController
@property (weak) id<SamplePickerDelegate> samplePickerDelegate;
@property UITableView *tableView;
@property UIButton *dismissButton;
@property NSArray *samples; //NSArray of strings;
@end
