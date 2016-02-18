//
//  MeterView.m
//  Evil Sampler
//
//  Created by david oneill on 2/17/16.
//  Copyright © 2016 David O'Neill. All rights reserved.
//

#import "MeterView.h"

@implementation MeterView{
    CGFloat _level;
    UIView *_coverView;
}
-(instancetype)init{
    return [self initWithFrame:CGRectZero];
}
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _coverView = [[UIView alloc]initWithFrame:(CGRect){CGPointZero,frame.size}];
        _coverView.backgroundColor = [UIColor blackColor];
        [self addSubview:_coverView];
    }
    return self;
}
-(void)layoutSubviews{
    [self layoutCover:self.level inRect:self.bounds];
}
-(void)layoutCover:(CGFloat)level inRect:(CGRect)rect{
    BOOL vertical = rect.size.width < rect.size.height;
    
    CGRect coverFrame = rect;
    
    
    if (vertical) {
        coverFrame.size.height -= rect.size.height * level;
    }
    else{
        coverFrame.origin.x = rect.size.width * level;
        coverFrame.size.width -= coverFrame.origin.x;
    }
    
    _coverView.frame = coverFrame;
}
-(void)drawRect:(CGRect)rect{
    
    
    CGFloat colors [] = {
        0.0, 1.0, 0.0, 1.0,
        
        0.0, 1.0, 0.0, 1.0,
        1.0, 1.0, 0.0, 1.0,
        
        
        1.0, 1.0, 0.0, 1.0,
        1.0, 0.0, 0.0, 1.0,
        
        1.0, 0.0, 0.0, 1.0
    };
    CGFloat transWidth = 0.075;
    CGFloat yellowPos = 0.8;
    CGFloat yellowWidth = 0.075;
    CGFloat locations[] = {
        0.0,
        
        yellowPos - yellowWidth - transWidth,
        yellowPos - yellowWidth,
        
        yellowPos + yellowWidth,
        yellowPos + yellowWidth + transWidth,
        
        1.0};
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 6);
    CGColorSpaceRelease(baseSpace);
    baseSpace = NULL;
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (rect.size.width < rect.size.height) {
        CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
        CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }
    else{
        CGPoint startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
        CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }
    
    
    CGGradientRelease(gradient), gradient = NULL;
    
}
-(void)setLevel:(CGFloat)level{
    _level = level;
    [self layoutCover:level inRect:self.bounds];
}

-(CGFloat)level{
    return _level;
}
@end





