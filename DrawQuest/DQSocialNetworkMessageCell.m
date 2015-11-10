//
//  DQSocialNetworkMessageCell.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 6/24/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DQSocialNetworkMessageCell.h"
#import "UIFont+DQAdditions.h"
#import "DQWebProfileShareViewController.h"
#import "UIColor+DQAdditions.h"

static inline NSString *DQSocialNetworkMessageCellPostTextWithURL(NSURL *url)
{
    return [NSString stringWithFormat:@"Come join me on @DrawQuest! Check out my drawings %@ and download the app! http://example.com/download", url];
}

@interface DQSocialNetworkMessageCell () <UITextViewDelegate>
@property (nonatomic, weak) IBOutlet UITextView *messageView;
@end

@implementation DQSocialNetworkMessageCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.contentView.layer.backgroundColor = [[UIColor dq_modalTableCellBackgroundColor] CGColor];
    self.contentView.layer.cornerRadius = 10.0f;
    self.contentView.layer.borderColor = [[UIColor dq_modalTableSeperatorColor] CGColor];
    self.contentView.layer.borderWidth = 1.0f;
    
    self.messageView.layer.cornerRadius = 5;
    self.messageView.layer.borderColor = [[UIColor colorWithWhite:0.85f alpha:1.0f] CGColor];
    self.messageView.layer.borderWidth = 1.0f;
    self.messageView.textColor = [UIColor dq_modalHighlightTextColor];
    self.messageView.font = [UIFont dq_modalTextFieldFont];
    self.messageView.text = DQSocialNetworkMessageCellPostTextWithURL(self.profileURL);
    self.messageView.contentInset = UIEdgeInsetsMake(-4, 0, 0, 0);
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.messageView.textColor = [UIColor dq_modalHighlightTextColor];
    self.messageView.font = [UIFont dq_modalTextFieldFont];
}

#pragma mark - Text view delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [[textView.text stringByReplacingCharactersInRange:range withString:text] length] <= 140;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (self.messageChangedBlock)
    {
        self.messageChangedBlock(textView.text);
    }
}

#pragma mark - Accessors

- (NSString *)messageText
{
    return self.messageView.text;
}

- (void)setProfileURL:(NSURL *)profileURL
{
    [self willChangeValueForKey:@"profileURL"];
    _profileURL = profileURL;
    self.messageView.text = DQSocialNetworkMessageCellPostTextWithURL(_profileURL);
}

@end
