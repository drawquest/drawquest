//
//  DQPublishShareOptionsView.h
//  DrawQuest
//
//  Created by David Mauro on 10/4/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DQPublishShareOptionsViewType) {
    DQPublishShareOptionsViewTypeFacebook,
    DQPublishShareOptionsViewTypeTwitter,
    DQPublishShareOptionsViewTypeEmail,
    DQPublishShareOptionsViewTypeTextMessage,
    DQPublishShareOptionsViewTypeCameraRoll,
    DQPublishShareOptionsViewTypeTumblr,
    DQPublishShareOptionsViewTypeFlickr,
    DQPublishShareOptionsViewTypeInstagram
};

@class DQPublishShareOptionsView;

@protocol DQPublishShareOptionsViewDelegate <NSObject>

- (void)publishShareOptionsView:(DQPublishShareOptionsView *)view didSelectShareOption:(DQPublishShareOptionsViewType)shareType;

@end

@interface DQPublishShareOptionsView : UIView

- (id)initWithFrame:(CGRect)frame shareOptions:(NSArray *)shareOptions delegate:(id<DQPublishShareOptionsViewDelegate>)delegate;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithFrame:shareOptions:delegate:);

- (BOOL)shareTypeIsHighlighted:(DQPublishShareOptionsViewType)shareType;
- (void)shareOption:(DQPublishShareOptionsViewType)shareType highlight:(BOOL)highlight;
- (void)showActivityForShareOption:(DQPublishShareOptionsViewType)shareType isActive:(BOOL)isActive;
- (void)flashSuccessForShareOption:(DQPublishShareOptionsViewType)shareType;
- (CGFloat)desiredHeight;

@end
