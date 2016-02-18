//
//  SamplePicker.m
//  Evil Sampler
//
//  Created by david oneill on 2/18/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import "SamplePicker.h"
@interface SamplePicker()<UITableViewDelegate,UITableViewDataSource>
//@property UITableView *tableView;
//@property UIButton *dismissButton;
@end
@implementation SamplePicker

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
-(void)viewDidLoad{
    [super viewDidLoad];
    if (!self.samples) {
        self.samples = @[];
    }
    self.dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.dismissButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.dismissButton];
    
    self.tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}
-(void)dismiss:(UIButton *)button{
    [self dismissViewControllerAnimated:1 completion:^{
        if (self.samplePickerDelegate && [self.samplePickerDelegate respondsToSelector:@selector(samplePickerDismissed:)]) {
            [self.samplePickerDelegate samplePickerDismissed:self];
        }
    }];
}
-(void)viewDidLayoutSubviews{
    CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
    CGRect bounds = self.view.bounds;
    CGRect dismissFrame = CGRectMake(10, CGRectGetMaxY(statusBarFrame), 100, 44);
    CGRect tableViewFrame = CGRectMake(0, CGRectGetMaxY(dismissFrame), bounds.size.width, bounds.size.height - CGRectGetMaxY(dismissFrame));
    
    self.dismissButton.frame = dismissFrame;
    self.tableView.frame = tableViewFrame;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.samples.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [self.samples[indexPath.row] lastPathComponent];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.samplePickerDelegate && [self.samplePickerDelegate respondsToSelector:@selector(samplePicker:pickedSample:)]) {
        [self.samplePickerDelegate samplePicker:self pickedSample:self.samples[indexPath.row]];
    }
}

@end














