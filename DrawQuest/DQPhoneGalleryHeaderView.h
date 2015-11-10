//
//  DQPhoneGalleryHeaderView.h
//  DrawQuest
//
//  Created by David Mauro on 9/27/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DQImageView.h"
#import "DQTimestampView.h"

@interface DQPhoneGalleryHeaderView : UIView

@property (nonatomic, strong) DQImageView *avatarImageView;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) DQTimestampView *timestampLabel;
@property (nonatomic, strong) DQImageView *questTemplateImageView;

@property (nonatomic, assign) BOOL hasAttributedAuthor;

@property (nonatomic, copy) dispatch_block_t inviteToQuestBlock;
@property (nonatomic, copy) dispatch_block_t moreOptionsBlock;
@property (nonatomic, copy) dispatch_block_t showEditorBlock;
@property (nonatomic, copy) dispatch_block_t showProfileBlock;
@property (nonatomic, copy) dispatch_block_t shareButtonTappedBlock;

- (void)setTemplateImageURL:(NSString *)imageURL;

@end
