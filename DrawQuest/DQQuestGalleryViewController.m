//
//  DQQuestGalleryViewController.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/18/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQQuestGalleryViewController.h"
#import "DQQuest.h"
#import "DQComment.h"
#import "DQAccountController.h"
#import "DQGalleryCommentCell.h"
#import "DQServiceController.h"
#import "DQDataStoreController.h"
#import "DQTitleView.h"
#import "DQUploadOverlay.h"
#import "CVSEditorViewController.h"

@interface DQQuestGalleryViewController ()

@property (nonatomic, retain) DQQuest *quest;
@property (strong, nonatomic) NSString *focusedCommentID;

- (void)updateQuestFromCache;
- (void)drawButtonPressed:(id)sender;

@end


@implementation DQQuestGalleryViewController

@synthesize questID;
@synthesize quest;
@synthesize focusedCommentID;

#pragma mark Initialization

- (id)initWithQuestID:(NSString *)inQuestID
{
    self = [self initWithQuestID:inQuestID focusedCommentID:nil];
    if (!self) {
        return nil;
    }

    return self;
}

- (id)initWithQuestID:(NSString *)inQuestID focusedCommentID:(NSString *)inScrolledCommentID
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.questID = inQuestID;
    self.focusedCommentID = inScrolledCommentID;
            
    return self;
}

- (void)dealloc
{
    [quest release];
    [questID release];
    [focusedCommentID release];
    
    [[DQAccountController sharedInstance].dataStoreController removeObserver:self];
    
    [super dealloc];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Right Button Item
    UIView *drawOffsetView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 251.0f, 70.0f)] autorelease];
    UIButton *drawButton = [UIButton buttonWithType:UIButtonTypeCustom];
    drawButton.frame = CGRectMake(8.0f, 17.0f, 281.0f, 53.0f);
    [drawOffsetView addSubview:drawButton];
    [drawButton setImage:[UIImage imageNamed:@"button_draw"] forState:UIControlStateNormal];
    [drawButton setImage:[UIImage imageNamed:@"button_draw_hit"] forState:UIControlStateHighlighted];
    [drawButton addTarget:self action:@selector(drawButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.drawButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:drawOffsetView] autorelease];
    self.navigationItem.rightBarButtonItem = self.drawButtonItem;
    
    DQTitleView *titleView = [[[DQTitleView alloc] initWithStyle:DQTitleViewStyleNavigationBar] autorelease];
    titleView.text = self.quest.title;
    self.navigationItem.titleView = titleView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[DQAccountController sharedInstance].dataStoreController addObserver:self action:@selector(questsUpdated:) forEntityName:@"Quest"];
    
    if (self.focusedCommentID) {
        [self scrollToCommentWithID:self.focusedCommentID];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[DQAccountController sharedInstance].serviceController requestCommentsForQuestWithServerID:self.questID];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[DQAccountController sharedInstance].dataStoreController removeObserver:self];
}

#pragma mark Accessors

- (void)setQuestID:(NSString *)inQuestID
{
    [inQuestID retain];
    [questID release];
    questID = inQuestID;
    
    [self updateQuestFromCache];
}

- (void)setQuest:(DQQuest *)inQuest
{
    [inQuest retain];
    [quest release];
    quest = inQuest;
    
    self.comments = inQuest.sortedComments;
}

#pragma mark Upload

- (void)postCommentWithDrawingData:(NSData *)inData
{
    DQComment *placeholderComment = [[DQAccountController sharedInstance].dataStoreController createPlaceholderCommentForQuestID:self.questID];
    [self updateQuestFromCache];
    
    [[DQAccountController sharedInstance].serviceController requestPostCommentForQuestID:self.questID withImageData:inData placeholderID:placeholderComment.identifier progressBlock:^(STHTTPRequest *inRequest) {

        NSInteger commentIndex = [self.comments indexOfObject:placeholderComment];
        
        UITableView *tableView = (UITableView *)[self.slidingView viewForIndex:commentIndex];
        DQGalleryCommentCell *cell = (DQGalleryCommentCell *)tableView.tableHeaderView;
        DQUploadOverlay *uploadOverlay = cell.uploadOverlay;
        
        if (!inRequest.error) {
            float progress = [inRequest.uploadPercentComplete floatValue];
            [uploadOverlay.progressView setProgress:progress animated:YES];
        } else {
            [uploadOverlay.retryButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [uploadOverlay.cancelButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            uploadOverlay.state = DQUploadOverlayStateFailed;
        }
    }];
}

#pragma mark STSlidingGalleryView

- (void)galleryView:(STSlidingGalleryView *)inGalleryView didFocusView:(UIView *)inView forIndex:(NSInteger)inIndex
{
    DQComment *focusedComment = [self.comments objectAtIndex:inIndex];
    self.focusedCommentID = focusedComment.serverID;
}

#pragma mark DQGalleryViewController

- (void)updateComments
{
    [self updateQuestFromCache];
    [super updateComments];
}

#pragma mark Private Methods

- (void)questsUpdated:(NSDictionary *)inUserInfo
{
    [self updateComments];
    
    if (self.focusedCommentID) {
        [self scrollToCommentWithID:self.focusedCommentID];
    }
}

- (void)updateQuestFromCache
{
    if (!self.questID.length) {
        return;
    }
    
    self.quest = [[DQAccountController sharedInstance].dataStoreController questForServerID:self.questID];
    //self.comments = [[DQAccountController sharedInstance].dataStoreController commentsForQuestWithServerID:self.questID];
}

- (void)drawButtonPressed:(id)sender
{
    CVSEditorViewController *editorViewController = [[CVSEditorViewController alloc] initWithQuest:self.quest];
    self.basementViewController.topViewController = editorViewController;
    [editorViewController release];
}

@end
