//
//  DQSocialNetworkButtonHeaderView.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-04.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSocialNetworkButtonHeaderView.h"
#import "UIFont+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "UIView+STAdditions.h"

@interface DQSocialNetworkButtonHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) UIButton *facebookButton;
@property (nonatomic, readwrite, weak) UIButton *twitterButton;

@end

@implementation DQSocialNetworkButtonHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];

    UIButton *facebookButton = [self buttonWithAction:@selector(facebookButtonTapped:)];
    facebookButton.frameOrigin = CGPointMake(340.0, 16.0);
    [self addSubview:facebookButton];
    self.facebookButton = facebookButton;

    UIButton *twitterButton = [self buttonWithAction:@selector(twitterButtonTapped:)];
    twitterButton.frameOrigin = CGPointMake(414.0, 16.0);
    [self addSubview:twitterButton];
    self.twitterButton = twitterButton;

    [self toggleImageForSocialNetwork:@"facebook" on:self.facebookSharing forButton:_facebookButton];
    [self toggleImageForSocialNetwork:@"twitter" on:self.twitterSharing forButton:_twitterButton];

    self.titleLabel.textColor = [UIColor dq_modalTableHeaderTextColor];
    self.titleLabel.font = [UIFont dq_modalTableHeaderFont];
}

#pragma mark - Actions

- (void)facebookButtonTapped:(UIButton *)sender
{
    _facebookSharing = !_facebookSharing;
    [self toggleImageForSocialNetwork:@"facebook" on:self.facebookSharing forButton:self.facebookButton];
    [self invokeValueChangedBlock];
}

- (void)twitterButtonTapped:(UIButton *)sender
{
    _twitterSharing = !_twitterSharing;
    [self toggleImageForSocialNetwork:@"twitter" on:self.twitterSharing forButton:self.twitterButton];
    [self invokeValueChangedBlock];
}

#pragma mark - Helpers

- (UIButton *)buttonWithAction:(SEL)selector
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setFrame:CGRectMake(0.0f, 0.0f, 64.0f, 32.0f)];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)toggleImageForSocialNetwork:(NSString *)name on:(BOOL)on forButton:(UIButton *)button
{
    const int NStates = 3;
    const UIControlState states[NStates] = { UIControlStateNormal, UIControlStateHighlighted, UIControlStateSelected };
    for (int i = 0; i < NStates; i++)
    {
        UIImage *checkboxImage = [self imageForCheckboxForCheckedState:on];
        UIImage *networkImage = [self imageForServiceName:name on:on forState:states[i]];
        UIImage *image = [self _compositeImageForCheckboxImage:checkboxImage serviceImage:networkImage];
        [button setImage:image forState:states[i]];
    }
}

- (UIImage *)imageForCheckboxForCheckedState:(BOOL)on
{
    static NSString *checkedSuffix = @"checked";
    static NSString *emptySuffix = @"empty";
    NSString *checkboxImageName = [NSString stringWithFormat:@"checkbox_%@", on ? checkedSuffix : emptySuffix];
    return [UIImage imageNamed:checkboxImageName];
}

- (UIImage *)imageForServiceName:(NSString *)name on:(BOOL)on forState:(UIControlState)state
{
    NSString *stateSuffix = @"";
    switch (state)
    {
        case UIControlStateHighlighted:
            stateSuffix = @"";
            break;
        case UIControlStateSelected:
            stateSuffix = @"";
            break;
        default:
            stateSuffix = on ? @"" : @"_deactivated";
            break;
    }
    NSString *buttonName = [NSString stringWithFormat:@"icon_%@%@", name, stateSuffix];
    return [UIImage imageNamed:buttonName];
}

- (void)invokeValueChangedBlock
{
    if (self.valueChangedBlock)
        self.valueChangedBlock(self, self.facebookSharing, self.twitterSharing);
}

#pragma mark - Accessors

- (void)setTitle:(NSString *)title
{
    [self willChangeValueForKey:@"title"];
    _title = [title copy];
    self.titleLabel.text = _title;
    [self didChangeValueForKey:@"title"];
}

- (void)setTwitterSharing:(BOOL)twitterSharing
{
    [self willChangeValueForKey:@"twitterSharing"];
    _twitterSharing = twitterSharing;
    [self toggleImageForSocialNetwork:@"twitter" on:_twitterSharing forButton:self.twitterButton];
    [self didChangeValueForKey:@"twitterSharing"];
}

- (void)setFacebookSharing:(BOOL)facebookSharing
{
    [self willChangeValueForKey:@"facebookSharing"];
    _facebookSharing = facebookSharing;
    [self toggleImageForSocialNetwork:@"facebook" on:_facebookSharing forButton:self.facebookButton];
    [self didChangeValueForKey:@"facebookSharing"];
}

#pragma mark - Private Helpers

- (UIImage *)_compositeImageForCheckboxImage:(UIImage *)checkboxImage serviceImage:(UIImage *)serviceImage
{
    static CGFloat spacing = 4.0f;
    
    CGSize compositeImageSize = CGSizeZero;
    compositeImageSize.height = MAX(checkboxImage.size.height, serviceImage.size.height);
    compositeImageSize.width = (checkboxImage.size.width + spacing + serviceImage.size.width);
    
    UIGraphicsBeginImageContextWithOptions(compositeImageSize, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect rect = CGRectMake(0, 0, compositeImageSize.width, compositeImageSize.height);
    CGContextClearRect(ctx, rect);
    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextFillRect(ctx, rect);
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, compositeImageSize.height);
    CGContextConcatCTM(ctx, flipVertical);
    
    CGPoint imagePoint = CGPointZero;
    CGContextDrawImage(ctx, (CGRect){ imagePoint, serviceImage.size }, serviceImage.CGImage);
    
    imagePoint.x += serviceImage.size.width + spacing;
    CGContextDrawImage(ctx, (CGRect){ imagePoint, checkboxImage.size }, checkboxImage.CGImage);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
