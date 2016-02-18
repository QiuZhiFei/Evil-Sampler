//
//  ViewController.m
//  Evil Sampler
//
//  Created by david oneill on 2/16/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "DUnit.h"
#import "SoundManager.h"
#import "MeterView.h"
#import <CoreMotion/CoreMotion.h>
#import "SamplePicker.h"


@implementation UIColor (ColorExt)
-(UIColor *)colorWithBrightness:(CGFloat)brightness{
    CGFloat comp[4];
    [self getHue:&comp[0] saturation:&comp[1] brightness:&comp[2] alpha:&comp[3]];
    return [UIColor colorWithHue:comp[0] saturation:comp[1] brightness:brightness alpha:comp[3]];
}
@end



@interface ViewController ()<SamplePickerDelegate,UICollisionBehaviorDelegate>
@property MeterView *meterView;
@end

@implementation ViewController{
    NSArray *buttons;
    NSArray *buttonColors;
    
    UIDynamicAnimator* _animator;
    UIGravityBehavior* _gravity;
    CMMotionManager *_motionManager;
    NSOperationQueue *_motionQueue;
    
    
    UIButton *fallingButton;
    BOOL _falling;
    UIInterfaceOrientationMask currentOrientation;
    
    
    UIButton *editSampleButton;
    BOOL _sampleEdit;
    int buttonIndexEditSample;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addUIElements];
    
    
    SoundManager *soundManager = [SoundManager sharedInstance];
    NSArray *allFiles = [[NSBundle mainBundle] pathsForResourcesOfType:NULL inDirectory:@"Sounds"];
    soundManager.audioFiles = [allFiles subarrayWithRange:NSMakeRange(0, 16)];
    
    
    
    /* 
     This is the core motion queue and block that sets gravity using device accelerometer.  Only active when in "_falling" mode.
     */
    
    _motionQueue = [[NSOperationQueue alloc] init];
    _motionManager = [[CMMotionManager alloc] init];
    [_motionManager startDeviceMotionUpdatesToQueue:_motionQueue withHandler:^(CMDeviceMotion *motion, NSError *error) {
        if (!_falling) {
            return;
        }
        CMAcceleration gravity = motion.gravity;
        dispatch_async(dispatch_get_main_queue(), ^{
            _gravity.gravityDirection = transAccToGrav(gravity,self.interfaceOrientation);
        });
    }];
    
    /*
     This is my animation timer, it calls displayLinkAction at 15 fps.  Tried 60fps and it audio pulsations were choppy,  so 15fps with short UIKit animations smoothed it out nicely.
     */
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
    displayLink.frameInterval = 4;
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

}


-(void)addUIElements{
    NSMutableArray *_buttons = [[NSMutableArray alloc]init];
    NSMutableArray *_colors = [[NSMutableArray alloc]init];
    for (int i = 0; i < 16; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.backgroundColor = nextColor();
        [_colors addObject:button.backgroundColor];
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:button];
        [_buttons addObject:button];
    }
    
    buttons = _buttons;
    buttonColors = _colors;
    
    
    CGSize size = self.view.frame.size;
    self.meterView = [[MeterView alloc]initWithFrame:CGRectMake(10, 10, size.width - 20, 50)];
    [self.view addSubview:self.meterView];
    
    
    fallingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [fallingButton.titleLabel setFont:[UIFont boldSystemFontOfSize:30]];
    [fallingButton setTitle:@"\u2193" forState:UIControlStateNormal];
    [fallingButton addTarget:self action:@selector(fallingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:fallingButton];
 
    editSampleButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [editSampleButton addTarget:self action:@selector(editSample:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:editSampleButton];
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return _falling ? currentOrientation : UIInterfaceOrientationMaskAll;
}

-(void)viewDidAppear:(BOOL)animated{
    CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
    CGRect bounds = self.view.bounds;
    bounds.origin.y += statusBarFrame.size.height;
    bounds.size.height -= statusBarFrame.size.height;
    
    [self layout:bounds];
}
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
    
    CGRect bounds = (CGRect){CGPointZero,size};
    bounds.origin.y += statusBarFrame.size.height;
    bounds.size.height -= statusBarFrame.size.height;
    
    CGRect newBounds = (CGRect){bounds.origin,CGSizeMake(bounds.size.width, bounds.size.height)};
    [UIView animateWithDuration:coordinator.transitionDuration animations:^{
        [self layout:newBounds];
    }];
    
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{

    if ((self.interfaceOrientation == UIInterfaceOrientationPortrait ||
        self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) &&
        (toInterfaceOrientation == UIInterfaceOrientationPortrait ||
         toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)){
            return;
    }
    else if ((self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
             self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) &&
            (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
             toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)){
                return;
            }
    
    CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
    
    CGRect bounds = self.view.bounds;
    bounds.origin.y += statusBarFrame.size.height;
    bounds.size.width -= statusBarFrame.size.height;
    
    CGRect newBounds = (CGRect){bounds.origin,CGSizeMake(bounds.size.height, bounds.size.width)};
    [UIView animateWithDuration:duration animations:^{
        [self layout:newBounds];
    }];
}


-(void)layout:(CGRect)bounds{
    
    CGRect buttonsFrame = bounds;
    CGFloat meterHeight = 4;
    
    CGFloat inset = MIN(bounds.size.height, bounds.size.width) / 40;
    if (bounds.size.height > bounds.size.width) {
        buttonsFrame.size.height = bounds.size.width;
        buttonsFrame.origin.y = (bounds.size.height - buttonsFrame.size.height) / 2;
        self.meterView.frame = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, meterHeight);
    }
    else{
        buttonsFrame.size.width = bounds.size.height;
        buttonsFrame.origin.x = (bounds.size.width - buttonsFrame.size.width) / 2;
        self.meterView.frame = CGRectMake(bounds.origin.x, bounds.origin.y, meterHeight, bounds.size.height);
    }
    
    CGRect buttonframe = (CGRect) {buttonsFrame.origin,CGSizeMake(buttonsFrame.size.width / 4, buttonsFrame.size.height / 4)};
    for (int i = 0; i < 4; i++) {
        buttonframe.origin.y = buttonsFrame.origin.y + i * buttonframe.size.height;
        for (int j = 0; j < 4; j++) {
            int buttonIndex = (i * 4) + j;
            buttonframe.origin.x = buttonsFrame.origin.x + j * buttonframe.size.width;
            UIButton *button = buttons[buttonIndex];
            button.transform = CGAffineTransformIdentity;
            button.frame = CGRectInset(buttonframe, inset, inset);
            button.layer.cornerRadius = inset;
        }
        
    }
    
    CGSize bottomButtonsSize = CGSizeMake(40, 40);
    
    fallingButton.frame = CGRectMake(bounds.size.width - bottomButtonsSize.width - 10, bounds.size.height - bottomButtonsSize.height - 10, bottomButtonsSize.width, bottomButtonsSize.height);
    
    editSampleButton.layer.cornerRadius = inset;
    editSampleButton.frame = CGRectMake(10, bounds.size.height - bottomButtonsSize.height - 10, bottomButtonsSize.width, bottomButtonsSize.height);
    
}
-(void)setFalling:(BOOL)falling{
    
    if (falling && !_falling) {
        currentOrientation = translOrientToMask(self.interfaceOrientation);
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
        _gravity = [[UIGravityBehavior alloc] initWithItems:buttons];
        
        UIDynamicItemBehavior* itemBehaviour = [[UIDynamicItemBehavior alloc] initWithItems:buttons];
        itemBehaviour.elasticity = 0.8;
        [_animator addBehavior:itemBehaviour];
        
        _gravity.magnitude = 2;
        
        [_animator addBehavior:_gravity];
        UICollisionBehavior* _collision;
        _collision = [[UICollisionBehavior alloc] initWithItems:buttons];
        _collision.translatesReferenceBoundsIntoBoundary = YES;
        _collision.collisionDelegate = self;
        [_animator addBehavior:_collision];
        [fallingButton setTitle:@"\u2191" forState:UIControlStateNormal];
    }
    else if (!falling && _falling){
        [_animator removeAllBehaviors];
        _animator = NULL;
        [UIView animateWithDuration:0.25 animations:^{
            [self layout:self.view.bounds];
        }];
        [fallingButton setTitle:@"\u2193" forState:UIControlStateNormal];
    }
    _falling = falling;
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id <UIDynamicItem>)item1 withItem:(id <UIDynamicItem>)item2 atPoint:(CGPoint)p{
    if ([[item1 class] isSubclassOfClass:[UIButton class]]) {
        [self buttonAction:(UIButton *)item1];
    }
    if ([[item2 class] isSubclassOfClass:[UIButton class]]) {
        [self buttonAction:(UIButton *)item2];
    }
}


-(void)displayLinkAction:(CADisplayLink *)displayLink{
    SoundManager *soundManager = [SoundManager sharedInstance];

    float dur = displayLink.duration * displayLink.frameInterval;
    UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction;
    
    int i = 0;
    for (UIButton *button in buttons) {
    
        if ([soundManager deciblesHold:(int)button.tag] > 0.01) {
            float dec = [soundManager decibles:(int)button.tag];
            float scale = 1 + (dec * 1.5);
            CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
            UIColor *color = [buttonColors[i] colorWithBrightness:MIN(1,0.5 + (dec * 3))];

            [UIView animateWithDuration:dur delay:0 options:options animations:^{
                if (!_falling) {
                    button.transform = transform;
                }
                button.backgroundColor = color;
            } completion:NULL];
        }
        i++;
    }
    [UIView animateWithDuration:dur delay:0 options:options animations:^{
        self.meterView.level = [soundManager deciblesMix] * 2;
    } completion:NULL];

}

-(void)buttonAction:(UIButton *)button{
    
    flashView(button);
    if (_sampleEdit) {
        [self pickSample:button];
        return;
    }
    
    [self.view insertSubview:button belowSubview:fallingButton];
    [[SoundManager sharedInstance]play:(int)button.tag withVolume:1];
}

-(void)fallingButtonAction:(UIButton *)button{
    [self setFalling:!_falling];
}
-(void)setSampleEdit:(BOOL)sampleEdit{
    if (sampleEdit == _sampleEdit) {
        return;
    }
    if (sampleEdit) {
        for (UIButton *button in buttons) {
            button.layer.borderColor = [[UIColor whiteColor]CGColor];
            button.layer.borderWidth = 2;
            editSampleButton.layer.borderColor = [[UIColor whiteColor]CGColor];
            editSampleButton.layer.borderWidth = 2;
            
        }
    }
    else{
        for (UIButton *button in buttons) {
            button.layer.borderWidth = 0;
            editSampleButton.layer.borderWidth = 0;
        }
    }
    _sampleEdit = sampleEdit;
}

-(BOOL)sampleEdit{
    return _sampleEdit;
}
-(void)editSample:(UIButton *)button{
    [self setFalling:0];
    [self setSampleEdit:!_sampleEdit];
}
-(void)pickSample:(UIButton *)button{
    [self editSample:0];
    button.layer.borderColor = [[UIColor whiteColor]CGColor];
    button.layer.borderWidth = 2;
    buttonIndexEditSample = (int)button.tag;
    SamplePicker *samplePicker = [[SamplePicker alloc]initWithNibName:NULL bundle:NULL];
    samplePicker.samplePickerDelegate = self;
    samplePicker.samples = [[NSBundle mainBundle] pathsForResourcesOfType:NULL inDirectory:@"Sounds"];
    
    NSArray *audioFiles = [[SoundManager sharedInstance]audioFiles];
    NSString *buttonSample = [audioFiles objectAtIndex:button.tag];
    int selectedRow = (int)[samplePicker.samples indexOfObject:buttonSample];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedRow inSection:0];
    
    
    [self presentViewController:samplePicker animated:1 completion:^{
        [samplePicker.tableView selectRowAtIndexPath:selectedIndexPath animated:1 scrollPosition:UITableViewScrollPositionMiddle];
    }];
}


-(void)samplePicker:(SamplePicker *)samplePicker pickedSample:(NSString *)sample{
    [[SoundManager sharedInstance]changeFile:sample atIndex:buttonIndexEditSample];
    [[SoundManager sharedInstance] play:buttonIndexEditSample withVolume:1];
}
-(void)samplePickerDismissed:(SamplePicker *)samplePicker{
    UIButton *editedButton = buttons[buttonIndexEditSample];
    editedButton.layer.borderWidth = 0;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}
- (BOOL)prefersStatusBarHidden{
    return 0;
}

void flashView(UIView *view){
    UIView *whiteView = [[UIView alloc]initWithFrame:view.bounds];
    whiteView.layer.cornerRadius = view.layer.cornerRadius;
    whiteView.backgroundColor = [UIColor whiteColor];
    whiteView.alpha = 0.25;
    whiteView.userInteractionEnabled = 0;
    [view addSubview:whiteView];
    [UIView animateWithDuration:0.3 animations:^{
        whiteView.alpha = 0;
    } completion:^(BOOL finished) {
        [whiteView removeFromSuperview];
    }];
}

static UIColor *nextColor(){
    static int hueInt = 0;
    hueInt = hueInt + 3;
    float hue = (float)(hueInt % 10) * 0.1;
    return [UIColor colorWithHue:hue saturation:1 brightness:0.3 alpha:1];
}
static UIInterfaceOrientationMask translOrientToMask(UIInterfaceOrientation orientation){
    UIInterfaceOrientationMask mask = 0;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            mask = UIInterfaceOrientationMaskLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            mask = UIInterfaceOrientationMaskLandscapeRight;
            break;
        case UIInterfaceOrientationPortrait:
            mask = UIInterfaceOrientationMaskPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            mask = UIInterfaceOrientationMaskPortraitUpsideDown;
            break;
            
        default:
            break;
    }
    return mask;
}


static CGVector transAccToGrav(CMAcceleration acc, UIInterfaceOrientation orientation){
    CGVector vec;
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:{
            vec.dy = acc.x;
            vec.dx = acc.y;
            break;
        }
        case UIInterfaceOrientationLandscapeRight:{
            vec.dx = -acc.y;
            vec.dy = -acc.x;
            break;
        }
        case UIInterfaceOrientationPortrait:
            vec.dy = -acc.y;
            vec.dx = acc.x;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            vec.dy = acc.y;
            vec.dx = -acc.x;
            break;
            
        default:
            break;
    }
    return vec;
}




@end
