//
//  DQGalleryErrorView.m
//  DrawQuest
//
//  Created by David Mauro on 4/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQGalleryErrorView.h"

#import "DQButton.h"

#import "UIColor+DQAdditions.h"
#import "UIFont+DQAdditions.h"
#import "UIView+STAdditions.h"

typedef enum {
    DQGalleryErrorViewButtonTypeDraw,
    DQGalleryErrorViewButtonTypeRetry,
    DQGalleryErrorViewButtonTypeNone
} DQGalleryErrorViewButtonType;

@interface DQGalleryErrorView ()

@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) DQButton *actionButton;
@property (nonatomic, copy) void (^buttonTappedBlock)(DQGalleryErrorView *v);

@end

@implementation DQGalleryErrorView

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame errorType:DQGalleryErrorViewTypeEmpty buttonTappedBlock:nil];
}

- (id)initWithFrame:(CGRect)frame errorType:(DQGalleryErrorViewType)errorType buttonTappedBlock:(void (^)(DQGalleryErrorView *v))buttonTappedBlock
{
    self = [super initWithFrame:frame];
    if (self)
    {
        NSString *errorString;
        DQGalleryErrorViewButtonType buttonType;
        switch (errorType) {
            case DQGalleryErrorViewTypeEmpty:
                errorString = DQLocalizedString(@"No one's drawn this Quest yet. Be the first!", @"No drawings exist for this Quest message");
                buttonType = DQGalleryErrorViewButtonTypeDraw;
                break;
            case DQGalleryErrorViewTypeDrawingNotFound:
                errorString = DQLocalizedString(@"Sorry, that drawing could not be found.", @"Drawing could not be found on server message");
                buttonType = DQGalleryErrorViewButtonTypeNone;
                break;
            case DQGalleryErrorViewTypeRequestFailed:
                errorString = DQLocalizedString(@"We couldn't load the gallery. Please try again.", @"Unknown error while loading Quest gallery, retry prompt");
                buttonType = DQGalleryErrorViewButtonTypeRetry;
                break;
            default:
                errorString = @"";
                break;
        }

        _panelView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 454.0f, 233.0f)];
        _panelView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_panelView];
        
        _errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _errorLabel.font = [UIFont dq_gallerySparseFont];
        _errorLabel.textColor = [UIColor dq_phoneGrayTextColor];
        _errorLabel.backgroundColor = [UIColor clearColor];
        _errorLabel.textAlignment = NSTextAlignmentCenter;
        _errorLabel.numberOfLines = 3;
        _errorLabel.text = errorString;
        [self addSubview:_errorLabel];
        
        if (buttonTappedBlock && buttonType != DQGalleryErrorViewButtonTypeNone)
        {
            _buttonTappedBlock = buttonTappedBlock;
            _actionButton = [DQButton buttonWithType:UIButtonTypeCustom];
            _actionButton.tintColorForBackground = YES;
            _actionButton.tintColor = [UIColor dq_greenColor];
            _actionButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
            _actionButton.layer.cornerRadius = 4.0f;
            switch (buttonType) {
                case DQGalleryErrorViewButtonTypeDraw:
                    [_actionButton setTitle:DQLocalizedString(@"Draw this", @"Draw this Quest button title") forState:UIControlStateNormal];
                    break;
                case DQGalleryErrorViewButtonTypeRetry:
                    [_actionButton setImage:[UIImage imageNamed:@"button_refresh_light"] forState:UIControlStateNormal];
                    [_actionButton setTitle:DQLocalizedString(@"Refresh", @"Refresh this Quest button title") forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
            _actionButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
            _actionButton.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 15.0f, 10.0f, 15.0f);
            [_actionButton sizeToFit];
            _actionButton.frameWidth = 150.0f;
            [_actionButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_actionButton];
        }
    }
    return self;
}

#pragma mark - UIView

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.panelView.center = self.center;
    CGRect panelFrame = self.panelView.frame;
    self.errorLabel.frame = CGRectInset(panelFrame, 35.0f, 20.0f);
    self.errorLabel.center = (CGPoint){.x = CGRectGetMidX(panelFrame), .y = panelFrame.origin.y + 80.0f};
    if (self.actionButton)
    {
        CGRect buttonFrame = self.actionButton.frame;
        self.actionButton.frameX = (int)(CGRectGetMidX(panelFrame) - CGRectGetMidX(buttonFrame));
        self.actionButton.frameY = (int)(panelFrame.origin.y + 170.0f - buttonFrame.size.height/2);
    }
}

#pragma mark - Actions

- (void)actionButtonTapped:(id)sender
{
    if (self.buttonTappedBlock)
    {
        self.buttonTappedBlock(self);
    }
}

@end
