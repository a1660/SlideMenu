//
//  SlideMenuController.m
//  SlideMenu
//
//  Created by 肖伟华 on 16/5/28.
//  Copyright © 2016年 XWH. All rights reserved.
//

#import "SlideMenuController.h"

static CGFloat const LeftMarginGesture = 45.0f;
static CGFloat const MinScaleContentView = 0.8f;
static CGFloat const MoveDistanceMenuView = 100.0f;
static CGFloat const MinScaleMenuView = 0.8f;
static double const DurationAnimation = 0.3f;

@interface SlideMenuController ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *menuViewContainer;
@property (nonatomic, strong) UIView *mainViewContainer;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIView *gestureRecognizerView;
@property (nonatomic, strong) UIPanGestureRecognizer *edgePanGesture;

@property (strong, readwrite, nonatomic) IBInspectable UIColor *mainViewShadowColor;
@property (assign, readwrite, nonatomic) IBInspectable CGSize mainViewShadowOffset;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat mainViewShadowOpacity;
@property (assign, readwrite, nonatomic) IBInspectable CGFloat mainViewShadowRadius;

@property (assign, nonatomic) CGFloat realContentViewVisibleWidth;
@property (assign, nonatomic) CGFloat mainViewScale;
@property (nonatomic,assign) BOOL menuHidden;

@end

@implementation SlideMenuController

- (id)initWithContentViewController:(UIViewController *)mainViewController leftMenuViewController:(UIViewController *)leftMenuViewController
{
    if(self = [super init]){
        self.mainViewController = mainViewController;
        self.leftMenuViewController = leftMenuViewController;
        [self prepare];
    }
    return self;
}
- (void)prepare
{
    _menuViewContainer = [[UIView alloc] init];
    _mainViewContainer = [[UIView alloc] init];
    _gestureRecognizerView = [[UIView alloc] init];
    _gestureRecognizerView.hidden = YES;// 初始没有隐藏导致rootController上手势无法正确识别
    _gestureRecognizerView.backgroundColor = [UIColor clearColor];
    _mainViewShadowColor = [UIColor blackColor];
    _mainViewShadowOffset = CGSizeZero;
    _mainViewShadowOpacity = 0.4f;
    _mainViewShadowRadius = 5.0f;
    _mainViewVisibleWidth = 120.0f;
    _mainViewScale = 1.0f;
    _menuHidden = YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.realContentViewVisibleWidth = self.mainViewVisibleWidth/MinScaleContentView;
    self.backgroundImageView = ({
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.image = self.backgroundImage;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView;
    });
    
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.menuViewContainer];
    [self.view addSubview:self.mainViewContainer];
    
    self.menuViewContainer.frame = self.view.bounds;
    self.mainViewContainer.frame = self.view.bounds;
    self.gestureRecognizerView.frame = self.view.bounds;
    
    self.menuViewContainer.backgroundColor = [UIColor clearColor];
    
    if (self.leftMenuViewController) {
        [self addChildViewController:self.leftMenuViewController];
        self.leftMenuViewController.view.frame = self.view.bounds;
        self.leftMenuViewController.view.backgroundColor = [UIColor clearColor];
        self.leftMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.menuViewContainer addSubview:self.leftMenuViewController.view];
        [self.leftMenuViewController didMoveToParentViewController:self];
    }
    
    NSAssert(self.mainViewController, @"内容视图不能为空");
    self.mainViewContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:self.mainViewController];
    self.mainViewController.view.frame = self.view.bounds;
    [self.mainViewContainer addSubview:self.mainViewController.view];
    [self.mainViewController didMoveToParentViewController:self];
    
    self.edgePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    self.edgePanGesture.delegate = self;
    [self.mainViewContainer addGestureRecognizer:self.edgePanGesture];
    
    [self.mainViewContainer addSubview:self.gestureRecognizerView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self.gestureRecognizerView addGestureRecognizer:tap];
    
    [self updateContentViewShadow];
}

- (void)showViewController:(UIViewController *)viewController{
    NSAssert([self.mainViewController isKindOfClass:[UINavigationController class]], @"住内容视图控制器不是UINavigationController");
    
    [((UINavigationController *)self.mainViewController) pushViewController:viewController animated:NO];
    [self hideMenu];
}
- (void)hideMenu{
    if(!self.menuHidden){
        [self showMenu:NO];
    }
}
- (void)showMenu
{
    if(self.menuHidden){
        [self showMenu:YES];
    }
}
#pragma method overwrite
- (void)setBackgroundImage:(UIImage *)backgroundImage{
    if(_backgroundImage != backgroundImage){
        _backgroundImage = backgroundImage;
        self.backgroundImageView.image = backgroundImage;
    }
}

#pragma custom selector

- (void)tapGestureRecognizer:(UITapGestureRecognizer *)recongnizer{
    if(!self.menuHidden){
        [self hideMenu];
    }
}

- (void)panGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)recognizer{
    
    CGPoint point = [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self updateContentViewShadow];
    }else if(recognizer.state == UIGestureRecognizerStateChanged){
        CGFloat menuVisibleWidth = self.view.bounds.size.width-self.realContentViewVisibleWidth;
        CGFloat delta = self.menuHidden ? point.x/menuVisibleWidth : (menuVisibleWidth+point.x)/menuVisibleWidth;
        
        CGFloat scale = 1-(1-MinScaleContentView)*delta;
        CGFloat menuScale = MinScaleMenuView + (1-MinScaleMenuView)*delta;
        if(self.menuHidden){
            //以内容视图最小缩放为界限
            if(scale < MinScaleContentView){//A
                self.mainViewContainer.transform = CGAffineTransformMakeTranslation(menuVisibleWidth, 0);
                self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,MinScaleContentView,MinScaleContentView);
                self.mainViewScale = MinScaleContentView;
                self.menuViewContainer.transform = CGAffineTransformMakeScale(1, 1);
                self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, 0, 0);
                
            }else{//大于最小界限又分大于等于1和小于1两种情况
                
                if(scale < 1){//B
                    self.mainViewContainer.transform = CGAffineTransformMakeTranslation(point.x, 0);
                    self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,scale, scale);
                    self.mainViewScale = scale;
                    self.menuViewContainer.transform = CGAffineTransformMakeScale(menuScale, menuScale);
                    self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, -MoveDistanceMenuView *(1-delta), 0);
                }else{//C
                    self.mainViewContainer.transform = CGAffineTransformMakeTranslation(0, 0);
                    self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,1, 1);
                    self.mainViewScale = 1;
                    self.menuViewContainer.transform = CGAffineTransformMakeScale(MinScaleMenuView, MinScaleMenuView);
                    self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, -MoveDistanceMenuView, 0);
                }
                
            }
            
        }else{
            
            if(scale > 1){//D
                self.mainViewContainer.transform = CGAffineTransformMakeTranslation(0, 0);
                self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,1,1);
                self.mainViewScale = 1;
                self.menuViewContainer.transform = CGAffineTransformMakeScale(MinScaleMenuView, MinScaleMenuView);
                self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, -MoveDistanceMenuView, 0);
            }else{
                if(scale>MinScaleContentView){//E
                    self.mainViewContainer.transform = CGAffineTransformMakeTranslation(point.x+menuVisibleWidth, 0);
                    self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,scale, scale);
                    self.mainViewScale = scale;
                    self.menuViewContainer.transform = CGAffineTransformMakeScale(menuScale, menuScale);
                    self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, -MoveDistanceMenuView * (1-delta), 0);
                }else{//F
                    self.mainViewContainer.transform =CGAffineTransformMakeTranslation(self.view.bounds.size.width-self.realContentViewVisibleWidth, 0);
                    self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,MinScaleContentView, MinScaleContentView);
                    self.mainViewScale = MinScaleContentView;
                    self.menuViewContainer.transform = CGAffineTransformMakeScale(1, 1);
                    self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, 0, 0);
                }
            }
        }
        
    }else if(recognizer.state == UIGestureRecognizerStateEnded){
        //        [self showMenu:(self.mainViewContainer.frame.origin.x > self.view.bounds.size.width/2)];
        [self showMenu:(self.mainViewScale < 1-(1-MinScaleContentView)/2)];
    }
}
- (void)showMenu:(BOOL)show{
    NSTimeInterval duration  = show ? (self.mainViewScale-MinScaleContentView)/(1-MinScaleContentView)*DurationAnimation : (1 - (self.mainViewScale-MinScaleContentView)/(1-MinScaleContentView))*DurationAnimation;
    
    [UIView animateWithDuration:duration animations:^{
        if(show){
            self.mainViewContainer.transform = CGAffineTransformMakeTranslation(self.view.bounds.size.width-self.realContentViewVisibleWidth, 0);
            self.mainViewContainer.transform = CGAffineTransformScale(self.mainViewContainer.transform,MinScaleContentView, MinScaleContentView);
            self.menuViewContainer.transform = CGAffineTransformIdentity;
            self.mainViewScale = MinScaleContentView;
        }else{
            
            self.mainViewContainer.transform = CGAffineTransformIdentity;
            self.mainViewScale = 1;
            self.menuViewContainer.transform = CGAffineTransformMakeScale(MinScaleMenuView, MinScaleMenuView);
            self.menuViewContainer.transform = CGAffineTransformTranslate(self.menuViewContainer.transform, -MoveDistanceMenuView, 0);
        }
    } completion:^(BOOL finished) {
        self.menuHidden = !show;
        self.gestureRecognizerView.hidden = !show;
    }];
}

#pragma method assist
- (void)updateContentViewShadow
{
    
    CALayer *layer = self.mainViewContainer.layer;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:layer.bounds];
    layer.shadowPath = path.CGPath;
    layer.shadowColor = self.mainViewShadowColor.CGColor;
    layer.shadowOffset = self.mainViewShadowOffset;
    layer.shadowOpacity = self.mainViewShadowOpacity;
    layer.shadowRadius = self.mainViewShadowRadius;
}

#pragma gesture delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    
    if(self.mainViewController.childViewControllers.count < 2){//这样只有在根视图控制器上起作用
        CGPoint point = [gestureRecognizer locationInView:gestureRecognizer.view];
        if(self.menuHidden){
            if(point.x <= LeftMarginGesture){
                return YES;
            }
        }else{
            return YES;
        }
    }
    return NO;
    
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if(gestureRecognizer == self.edgePanGesture){
        return YES;
    }
    return  NO;
}
@end
