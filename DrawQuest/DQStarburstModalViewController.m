//
//  DQStarburstModalViewController.m
//  DrawQuest
//
//  Created by David Mauro on 8/15/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQStarburstModalViewController.h"
#import "UIColor+DQAdditions.h"

@interface DQStarburstModalViewController ()

@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, weak) UIView *dropShadow;
@property (nonatomic, weak) UIImageView *starburstImageView;
@property (nonatomic, assign) CGRect viewControllerBounds;

@end

@implementation DQStarburstModalViewController

- (id)initWithViewController:(UIViewController *)viewController withBounds:(CGRect)bounds
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        self.viewControllerBounds = bounds;
        self.viewController = viewController;
        [self addChildViewController:self.viewController];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *starburstImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"starBurst"]];
    // Tweak starburst size
    starburstImageView.bounds = CGRectMake(0.0f, 0.0f, 1000.0f, 1000.0f);
    [self.view addSubview:starburstImageView];
    self.starburstImageView = starburstImageView;
    
    UIView *dropShadow = [[UIView alloc] initWithFrame:CGRectZero];
    dropShadow.layer.cornerRadius = 7.0f;
    dropShadow.layer.shadowColor = [[UIColor blackColor] CGColor];
    dropShadow.layer.shadowOpacity = 0.5f;
    dropShadow.layer.shadowRadius = 10.0f;
    dropShadow.layer.shadowOffset = CGSizeZero;
    dropShadow.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:dropShadow];
    self.dropShadow = dropShadow;
    
    [self.view addSubview:self.viewController.view];
    [self.viewController didMoveToParentViewController:self];
    self.viewController.view.clipsToBounds = YES;
    self.viewController.view.layer.cornerRadius = 7.0f;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSTimeInterval duration = 5.0f;
    CGFloat angle = M_PI / 3.33f;
    CGAffineTransform rotateTransform = CGAffineTransformRotate(self.starburstImageView.transform, angle);
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionRepeat| UIViewAnimationOptionCurveLinear animations:^{
        weakSelf.starburstImageView.transform = rotateTransform;
    } completion:nil];
    
    self.view.frame = self.view.superview.frame;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.viewController.view.bounds = self.viewControllerBounds;
    self.dropShadow.bounds = self.viewControllerBounds;
    self.dropShadow.center = self.viewController.view.center;
    self.starburstImageView.center = self.viewController.view.center;
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.dropShadow = nil;
        self.starburstImageView = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

@end
