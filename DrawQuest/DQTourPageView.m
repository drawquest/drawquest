//
//  DQTourPageView.m
//  DrawQuest
//
//  Created by David Mauro on 10/17/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTourPageView.h"

#import "DQButton.h"

#import "UIView+STAdditions.h"
#import "UIFont+DQAdditions.h"

@interface DQTapDownGestureRecognizer : UIGestureRecognizer

@property (nonatomic, assign, readwrite) UIGestureRecognizerState state;

@end

@interface DQTourPageView ()

@property (nonatomic, strong) UIImageView *gradientImageView;
@property (nonatomic, strong) UIImageView *foregroundImageView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong, readwrite) UIButton *button;
@property (nonatomic, strong) UIView *optionsView;
@property (nonatomic, strong) UIView *optionsDividerView;
@property (nonatomic, strong) DQButton *drawLaterButton;
@property (nonatomic, strong) DQButton *signInButton;
@property (nonatomic, assign) BOOL displayExtraOptions;

@end

@implementation DQTourPageView

- (id)initWithGradientImage:(UIImage *)gradientImage foregroundImage:(UIImage *)foregroundImage message:(NSString *)message displayExtraOptions:(BOOL)displayExtraOptions button:(UIButton *)button
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _gradientImageView = [[UIImageView alloc] initWithImage:gradientImage];
        [self addSubview:_gradientImageView];

        _foregroundImageView = [[UIImageView alloc] initWithImage:foregroundImage];
        [self addSubview:_foregroundImageView];

        _messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _messageLabel.text = message;
        _messageLabel.font = [UIFont dq_tourMessagesFont];
        _messageLabel.textColor = [UIColor whiteColor];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        _messageLabel.numberOfLines = 0;

        [self addSubview:_messageLabel];

        if (button)
        {
            _button = button;
            [self addSubview:_button];
        }

        _displayExtraOptions = displayExtraOptions;

        if (displayExtraOptions)
        {
            _optionsView = [[UIView alloc] initWithFrame:CGRectZero];
            _optionsView.backgroundColor = [UIColor clearColor];
            [self addSubview:_optionsView];

            _drawLaterButton = [DQButton buttonWithType:UIButtonTypeCustom];
            _drawLaterButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 3.0f, 0.0f, 3.0f);
            _drawLaterButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            _drawLaterButton.titleLabel.minimumScaleFactor = 0.5f;
            [_drawLaterButton setTitle:DQLocalizedString(@"Draw This Later", @"Option to draw the first quest at a later time") forState:UIControlStateNormal];
            __weak typeof(self) weakSelf = self;
            _drawLaterButton.tappedBlock = ^(DQButton *button) {
                if (weakSelf.drawLaterButtonTappedBlock)
                {
                    weakSelf.drawLaterButtonTappedBlock();
                }
            };
            _drawLaterButton.titleLabel.font = [UIFont dq_tourSecondaryButtonsFont];
            _drawLaterButton.backgroundColor = [UIColor clearColor];
            [_optionsView addSubview:_drawLaterButton];

            _signInButton = [DQButton buttonWithType:UIButtonTypeCustom];
            _signInButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 3.0f, 0.0f, 3.0f);
            _signInButton.titleLabel.adjustsFontSizeToFitWidth = YES;
            _signInButton.titleLabel.minimumScaleFactor = 0.5f;
            [_signInButton setTitle:DQLocalizedString(@"Already a Member?", @"Option to sign into DrawQuest if the user is already registered") forState:UIControlStateNormal];
            _signInButton.tappedBlock = ^(DQButton *button) {
                if (weakSelf.signInButtonTappedBlock)
                {
                    weakSelf.signInButtonTappedBlock();
                }
            };
            _signInButton.titleLabel.font = [UIFont dq_tourSecondaryButtonsFont];
            _signInButton.backgroundColor = [UIColor clearColor];
            [_optionsView addSubview:_signInButton];

            _optionsDividerView = [[UIView alloc] initWithFrame:CGRectZero];
            _optionsDividerView.backgroundColor = [UIColor whiteColor];
            [_optionsView addSubview:_optionsDividerView];
        }

    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat padding = 15.0f;

    self.messageLabel.frameWidth = self.frameWidth * (self.wideText ? 0.95 : 0.81);
    [self.messageLabel sizeToFit];

    CGPoint center = self.boundsCenter;
    center.y -= (padding + self.messageLabel.frameHeight + self.button.frameHeight)/1.1; // Tend towards pushing content up

    self.gradientImageView.center = center;
    self.foregroundImageView.frameCenterX = center.x;

    self.messageLabel.frameCenterX = center.x;

    self.button.frameCenterX = center.x;

    // Vertical alignment changes if we're displaying extra options
    if (self.displayExtraOptions)
    {
        self.foregroundImageView.frameCenterY = center.y + padding + self.messageLabel.frameHeight;
        self.messageLabel.frameMaxY = self.foregroundImageView.frameY - padding;
        self.button.frameY = self.foregroundImageView.frameMaxY;
    }
    else
    {
        self.foregroundImageView.frameCenterY = center.y;
        self.messageLabel.frameY = self.foregroundImageView.frameMaxY + padding;
        self.button.frameY = self.messageLabel.frameMaxY + padding;
    }

    self.optionsView.frameWidth = self.boundsSize.width;
    self.optionsView.frameHeight = 50.0f;
    self.optionsView.frameMaxY = self.frameMaxY;

    self.optionsDividerView.frameHeight = self.optionsView.frameHeight * 0.6;
    self.optionsDividerView.frameWidth = 0.5f;
    self.optionsDividerView.center = self.optionsView.boundsCenter;

    CGRect drawLaterFrame;
    CGRect signInFrame;
    CGRectDivide(self.optionsView.bounds, &drawLaterFrame, &signInFrame, self.optionsView.frameWidth/2, CGRectMinXEdge);
    self.drawLaterButton.frame = drawLaterFrame;
    self.signInButton.frame = signInFrame;
}

- (void)imageTapped:(id)sender
{
    if (self.imageTappedBlock)
    {
        self.imageTappedBlock();
    }
}

- (void)setImageTappedBlock:(dispatch_block_t)imageTappedBlock
{
    _imageTappedBlock = imageTappedBlock;
    
    DQTapDownGestureRecognizer *imageTap = [[DQTapDownGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.foregroundImageView addGestureRecognizer:imageTap];
    self.foregroundImageView.userInteractionEnabled = YES;
}

@end

@implementation DQTapDownGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateRecognized;
}

@end
