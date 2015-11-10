//
//  STBasementViewController.m
//
//  Created by Buzz Andersen on 9/25/12.
//  Copyright 2012 System of Touch. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "STBasementViewController.h"
#import "STUtils.h"
#import "CVSEditorViewController.h"

@interface STBasementViewController ()

//@property (nonatomic, retain) UIViewController *bottomViewController;
@property (nonatomic, assign) STBasementViewControllerEdge presentedEdge;

@property (nonatomic, strong) UIView *dimmerView;

- (void)_positionTopView:(UIView *)inView forPresentedEdge:(STBasementViewControllerEdge)inPresentedEdge offsetWidth:(CGFloat)inOffsetWidth;
- (void)_positionTopView:(UIView *)inView forPresentedEdge:(STBasementViewControllerEdge)inPresentedEdge offsetWidth:(CGFloat)inOffsetWidth animationDuration:(NSTimeInterval)inAnimationDuration;

@end


@implementation STBasementViewController

@synthesize topViewController;
@synthesize bottomViewController;
@synthesize presentedEdge;

#pragma mark Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        presentedEdge = STBasementViewControllerEdgeNone;
    }
    return self;
}



#pragma mark UIViewController

- (void)loadView
{
    UIView *containerView = [[UIView alloc] initWithFrame:[[[UIApplication sharedApplication] keyWindow] frame]];
    self.view = containerView;
}

- (void)viewDidLoad;
{
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
    return YES;
}

- (BOOL)shouldAutomaticallyForwardRotationMethods
{
    return YES;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return YES;
}

#pragma mark Accessors

- (void)setTopViewController:(UIViewController *)inTopViewController;
{
    // If the top view controller is being set to
    // nil, remove it as a child view controller
    // and remove its view as a subview of the
    // container
    if (topViewController) {
        [topViewController willMoveToParentViewController:nil];
        [topViewController removeFromParentViewController];
        [topViewController.view removeFromSuperview];
        [self.dimmerView removeFromSuperview];
        self.dimmerView = nil;
    }
    
    topViewController = inTopViewController;
    
    if (inTopViewController) {
        [self addChildViewController:inTopViewController];
        
        UIView *theTopView = inTopViewController.view;
        [self.view addSubview:theTopView];
        [topViewController didMoveToParentViewController:topViewController];
        
        self.dimmerView = [[DQBasementDimmerView alloc] initWithFrame:theTopView.bounds];
        self.dimmerView.userInteractionEnabled = YES;
        self.dimmerView.backgroundColor = [UIColor blackColor];
        self.dimmerView.alpha = 0.25f;
        self.dimmerView.hidden = YES;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideBottomView)];
        [self.dimmerView addGestureRecognizer:tapRecognizer];
        
        UISwipeGestureRecognizer *swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideBottomView)];
        swipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.dimmerView addGestureRecognizer:swipeRecognizer];
        
        [theTopView addSubview:self.dimmerView];

        [self _positionTopView:theTopView forPresentedEdge:self.presentedEdge offsetWidth:self.bottomViewController.view.frameWidth animationDuration:0.0];
    }
}

- (void)setBottomViewController:(UIViewController *)inBottomViewController;
{
    if (bottomViewController) {
        [bottomViewController willMoveToParentViewController:nil];
        [bottomViewController removeFromParentViewController];
        [bottomViewController.view removeFromSuperview];
    }
    
    bottomViewController = inBottomViewController;
    
    if (inBottomViewController) {
        [self addChildViewController:inBottomViewController];
        
        UIView *theBottomView = inBottomViewController.view;
        [self.view insertSubview:theBottomView belowSubview:self.topViewController.view];

        [self _positionBottomView:theBottomView forPresentedEdge:STBasementViewControllerEdgeNone];
    }
}

- (BOOL)basementIsVisible;
{
    return self.bottomViewController && (self.presentedEdge != STBasementViewControllerEdgeNone);
}

#pragma mark Presentation

- (BOOL)prefersStatusBarHidden
{
    if (self.presentedEdge != STBasementViewControllerEdgeNone)
    {
        return YES;
    }
    else if ([self.topViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *nc = (UINavigationController *)self.topViewController;
        return [nc.topViewController isKindOfClass:[CVSEditorViewController class]];
    }
    else
    {
        return NO;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

- (void)presentBottomViewController:(UIViewController *)inViewController fromEdge:(STBasementViewControllerEdge)inEdge;
{
    [self presentBottomViewController:inViewController fromEdge:inEdge animationDuration:STDefaultAnimationDuration];
}

- (void)presentBottomViewController:(UIViewController *)inViewController fromEdge:(STBasementViewControllerEdge)inEdge animationDuration:(NSTimeInterval)inAnimationDuration;
{
    if (!self.view || !self.topViewController || self.basementIsVisible) {
        return;
    }
    
    self.presentedEdge = inEdge;

    // Set the new view controller as the bottom view
    // controller.
    self.bottomViewController = inViewController;

    UIView *theTopView = self.topViewController.view;
    UIView *theBottomView = inViewController.view;
    
    // Position the views appropriately for the specified
    // edge.
    [self _positionBottomView:theBottomView forPresentedEdge:inEdge];
    [self _positionTopView:theTopView forPresentedEdge:inEdge offsetWidth:theBottomView.frameWidth animationDuration:inAnimationDuration];
}

- (void)setPresentedEdge:(STBasementViewControllerEdge)presentedEdge_
{
    presentedEdge = presentedEdge_;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)hideBottomView;
{
    [self hideBottomViewWithAnimationDuration:STDefaultAnimationDuration];
}

- (void)hideBottomViewWithAnimationDuration:(NSTimeInterval)inAnimationDuration;
{
    if (!self.bottomViewController || !self.basementIsVisible) {
        return;
    }
    
    UIView *topView = self.topViewController.view;
    
    [self.bottomViewController.view setUserInteractionEnabled:NO];
    
    [UIView animateWithDuration:inAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        topView.frameX = 0.0;
        topView.frameY = 0.0;
        
        self.dimmerView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.bottomViewController.view setUserInteractionEnabled:YES];
        if (finished)
        {
            self.dimmerView.hidden = YES;
            self.topViewController.view.clipsToBounds = NO;
            self.bottomViewController = nil;
            self.presentedEdge = STBasementViewControllerEdgeNone;
        }
    }];
}

#pragma mark Private Methods

- (void)_positionBottomView:(UIView *)inBottomView forPresentedEdge:(STBasementViewControllerEdge)inPresentedEdge;
{
    if (!bottomViewController) {
        return;
    }
    
    UIView *theBottomView = self.bottomViewController.view;
    CGFloat basementWidth = theBottomView.frameWidth;
    CGFloat basementHeight = theBottomView.frameHeight;
    
    // Position the bottom view appropriately for the
    // specified edge
    switch (inPresentedEdge) {
        case STBasementViewControllerEdgeLeft:
            theBottomView.frameY = 0.0;
            theBottomView.frameX = 0.0;
            break;
        case STBasementViewControllerEdgeRight:
            theBottomView.frameX = self.view.frameWidth - basementWidth;
            theBottomView.frameY = 0.0;
            break;
        case STBasementViewControllerEdgeTop:
            theBottomView.frameX = 0.0;
            theBottomView.frameY = 0.0;
            break;
        case STBasementViewControllerEdgeBottom:
            theBottomView.frameX = 0.0;
            theBottomView.frameY = self.view.frameHeight - basementHeight;
            break;
        default:
            theBottomView.frameY = 0.0;
            theBottomView.frameX = 0.0;
            break;
    }
}

- (void)_positionTopView:(UIView *)inView forPresentedEdge:(STBasementViewControllerEdge)inPresentedEdge offsetWidth:(CGFloat)inOffsetWidth;
{
    [self _positionTopView:inView forPresentedEdge:inPresentedEdge offsetWidth:inOffsetWidth animationDuration:0.0];
}

- (void)_positionTopView:(UIView *)inView forPresentedEdge:(STBasementViewControllerEdge)inPresentedEdge offsetWidth:(CGFloat)inOffsetWidth animationDuration:(NSTimeInterval)inAnimationDuration;
{
    if (!self.topViewController) {
        return;
    }
    
    void(^positionBlock)(void) = ^{
        UIView *theTopView = self.topViewController.view;

        switch (inPresentedEdge) {
            case STBasementViewControllerEdgeLeft:
                theTopView.frameX = inOffsetWidth;
                break;
            case STBasementViewControllerEdgeRight:
                theTopView.frameX = -inOffsetWidth;
                break;
            case STBasementViewControllerEdgeTop:
                theTopView.frameY = inOffsetWidth;
                break;
            case STBasementViewControllerEdgeBottom:
                theTopView.frameY = -inOffsetWidth;
                break;
            default:
                theTopView.frameX = 0.0;
                theTopView.frameY = 0.0;
                break;
        }
    };
    
    // Animate the top view slide from the specified edge
    if (inAnimationDuration > 0.0) {
        [UIView animateWithDuration:inAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            positionBlock();
            [self.topViewController.view bringSubviewToFront:self.dimmerView];
            self.dimmerView.hidden = NO;
            self.dimmerView.alpha = 0.25f;
            self.topViewController.view.clipsToBounds = YES;
        }
        completion:NULL];
    } else {
        positionBlock();
    }
}

@end

@implementation DQBasementDimmerView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

@end
