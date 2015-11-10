//
//  DQDrawingZoomViewController.m
//  DrawQuest
//
//  Created by David Mauro on 11/8/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQDrawingZoomViewController.h"

// Models
#import "DQComment.h"

// Views
#import "DQImageView.h"
#import "DQAlertView.h"

// Additions
#import "UIView+STAdditions.h"
#import "UIImage+DQAdditions.h"
#import "UIImage+ImageEffects.h"

@interface DQDrawingZoomViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *imagesWrapperView;
@property (nonatomic, weak) UIImageView *backgroundImageView;
@property (nonatomic, assign) BOOL allowCentering;
@property (nonatomic, assign) CGRect imageFrame;
@property (nonatomic, copy) dispatch_block_t didRotateBlock;

@end

@implementation DQDrawingZoomViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Fade in bg image
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage screenshot] applyDarkEffect]];
    backgroundImageView.center = self.view.boundsCenter;
    backgroundImageView.alpha = 0;
    [self.view addSubview:backgroundImageView];
    [UIView animateWithDuration:0.2f animations:^{
        backgroundImageView.alpha = 1;
    }];
    self.backgroundImageView = backgroundImageView;

    // Match size and placement
    self.imageFrame = CGRectMake(0.0f, 0.0f, 1212.0f, 908.0f);
    CGFloat initialScale = self.sourceView.frameWidth/CGRectGetWidth(self.imageFrame);
    CGPoint relativeCenter = [self.sourceView convertPoint:self.sourceView.boundsCenter toView:self.view.window];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.delegate = self;
    [self.view addSubview:scrollView];
    scrollView.minimumZoomScale = initialScale;
    scrollView.maximumZoomScale = 1.0f;
    self.scrollView = scrollView;

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.extendedLayoutIncludesOpaqueBars = YES;

    UIView *imagesWrapperView = [[UIView alloc] initWithFrame:self.imageFrame];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageDoubleTapped:)];
    doubleTap.numberOfTapsRequired = 2;
    [imagesWrapperView addGestureRecognizer:doubleTap];
    [self.scrollView addSubview:imagesWrapperView];
    self.imagesWrapperView = imagesWrapperView;

    DQImageView *previewImageView = [[DQImageView alloc] initWithFrame:self.imageFrame];
    previewImageView.imageURL = [self.comment imageURLForKey:DQImageKeyPhoneGallery];
    [imagesWrapperView addSubview:previewImageView];

    DQImageView *fullsizeImageView = [[DQImageView alloc] initWithFrame:self.imageFrame];
    fullsizeImageView.internalImageView.backgroundColor = [UIColor clearColor];
    fullsizeImageView.imageURL = [self.comment imageURLForKey:DQImageKeyGallery];
    [imagesWrapperView addSubview:fullsizeImageView];

    UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTapped:)];
    [closeTap requireGestureRecognizerToFail:doubleTap];
    [scrollView addGestureRecognizer:closeTap];

    [scrollView setZoomScale:initialScale animated:NO];
    imagesWrapperView.center = relativeCenter;

    // And zoom to center
    //CGFloat fullWidthScale = self.scrollView.frameWidth/CGRectGetWidth(self.imageFrame);
    [UIView animateWithDuration:0.3 animations:^{
        //[self.scrollView setZoomScale:fullWidthScale animated:NO];
        imagesWrapperView.center = [self centeredGalleryImagePoint];
    } completion:^(BOOL finished) {
        self.allowCentering = YES;
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.scrollView.frame = self.view.bounds;
    self.backgroundImageView.frame = self.view.bounds;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat radians = 0.0f;
    if (currentOrientation == UIInterfaceOrientationLandscapeLeft)
    {
        radians = M_PI/2.0f;
    }
    else if (currentOrientation == UIInterfaceOrientationLandscapeRight)
    {
        radians = -M_PI/2.0f;
    }
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    rotationTransform = CGAffineTransformRotate(rotationTransform, radians);
    self.backgroundImageView.transform = rotationTransform;

    [self scrollViewDidZoom:self.scrollView];

    if (self.didRotateBlock)
    {
        self.didRotateBlock();
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)imageDoubleTapped:(id)sender
{
    CGFloat fullWidthScale = self.scrollView.frameWidth/CGRectGetWidth(self.imageFrame);
    CGFloat threshold = (1.0 - fullWidthScale)/2.0f;
    if (self.scrollView.zoomScale < 1.0 - threshold)
    {
        [self.scrollView setZoomScale:1.0 animated:YES];
    }
    else
    {
        [self.scrollView setZoomScale:fullWidthScale animated:YES];
    }
}

- (void)scrollViewTapped:(id)sender
{
    [self close];
}

- (void)close;
{
    __weak typeof(self) weakSelf = self;
    dispatch_block_t readyBlock = ^{
        CGFloat duration = 0.2;

        // Start image fade
        [UIView animateWithDuration:duration animations:^{
            weakSelf.backgroundImageView.alpha = 0;
        }];

        // As we put the image back
        weakSelf.allowCentering = NO;
        CGFloat initialScale = weakSelf.sourceView.frameWidth/CGRectGetWidth(weakSelf.imageFrame);
        CGPoint relativeCenter = [weakSelf.sourceView convertPoint:weakSelf.sourceView.boundsCenter toView:weakSelf.view.window];
        [UIView animateWithDuration:duration animations:^{
            [weakSelf.scrollView setZoomScale:initialScale animated:NO];
            weakSelf.imagesWrapperView.center = relativeCenter;
        } completion:^(BOOL finished) {
            if (weakSelf.closeWindowBlock)
            {
                weakSelf.closeWindowBlock(weakSelf);
            }
        }];
    };

    // Tell them to go back to portrait
    __block DQAlertView *alertView = nil;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    NSString *message = nil;
    if (orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        message = DQLocalizedString(@"↺ Please flip your device right-side-up to continue.", @"displayed in overlay to tell user what they must do before they can proceed");
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft)
    {
        message = DQLocalizedString(@"↺ Please rotate your device back to Portrait to continue.", @"displayed in overlay to tell user what they must do before they can proceed");
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight)
    {
        message = DQLocalizedString(@"↻ Please rotate your device back to Portrait to continue.", @"displayed in overlay to tell user what they must do before they can proceed");
    }

    if (message)
    {
        self.didRotateBlock = ^{
            if ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait)
            {
                [alertView dismissWithClickedButtonIndex:0 animated:NO];
                alertView = nil;
                weakSelf.didRotateBlock = nil;
                readyBlock();
            }
        };
        alertView = [[DQAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        readyBlock();
    }
}

- (CGPoint)centeredGalleryImagePoint
{
    CGFloat offsetX = (self.scrollView.bounds.size.width > self.scrollView.contentSize.width)? (self.scrollView.bounds.size.width - self.scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (self.scrollView.bounds.size.height > self.scrollView.contentSize.height)? (self.scrollView.bounds.size.height - self.scrollView.contentSize.height) * 0.5 : 0.0;
    return CGPointMake(self.scrollView.contentSize.width * 0.5 + offsetX, self.scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imagesWrapperView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (self.allowCentering)
    {
        self.imagesWrapperView.center = [self centeredGalleryImagePoint];
    }
}

@end
