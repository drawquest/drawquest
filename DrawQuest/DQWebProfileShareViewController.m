//
//  DQWebProfileShareViewController.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "UIColor+DQAdditions.h"
#import "DQWebProfileShareViewController.h"
#import "DQPrivateServiceController.h"
#import "UIButton+DQAdditions.h"
#import "DQShareWebProfileCell.h"
#import "DQSocialNetworkButtonHeaderView.h"
#import "DQAccount.h"
#import "DQTwitterController.h"
#import "DQFacebookController.h"
#import "DQSocialNetworkMessageCell.h"
#import "DQAccount.h"
#import "DQAlertView.h"

static NSString *DQWebProfileSharePreviewURLStringKey = @"WebProfilePreviewURLString";
static const CGFloat kDQWebProfileShareInset = 30.0f;

@interface DQWebProfileShareViewController () <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

@property (nonatomic, weak) UIWebView *previewWebView;
@property (nonatomic, weak) UIImageView *previewWebViewHeaderImageView;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, readwrite, strong) NSString *shareMessage;
@property (nonatomic) BOOL sharing;
@property (nonatomic, readwrite) BOOL shareOnFacebook;
@property (nonatomic, readwrite) BOOL shareOnTwitter;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *twitterAuthRequestSourceView;

@end

@implementation DQWebProfileShareViewController
{
    BOOL _keyboardShowing;
}

- (void)dealloc
{
    _previewWebView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
}

- (instancetype)initWithPrivacy:(BOOL)privacy twitterController:(DQTwitterController *)twitterController facebookController:(DQFacebookController *)facebookController delegate:(id<DQViewControllerDelegate>)delegate
{
    if ((self = [super initWithDelegate:delegate]))
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        _sharing = privacy;
        _twitterController = twitterController;
        _facebookController = facebookController;
    }
    return self;
}

- (void)loadView
{
    UIImageView *previewWebViewHeaderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 480.0f, 24.0f)];
    previewWebViewHeaderImageView.image = [[UIImage imageNamed:@"webProfileNavBarResizeable"] resizableImageWithCapInsets:UIEdgeInsetsMake(24.0f, 60.0f, 24.0f, 4.0f)];
    self.previewWebViewHeaderImageView = previewWebViewHeaderImageView;

    UIWebView *previewWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
    previewWebView.userInteractionEnabled = NO;
    previewWebView.scrollView.scrollEnabled = NO;
    previewWebView.delegate = self;
    previewWebView.scalesPageToFit = YES;
    previewWebView.layer.borderColor = [[UIColor dq_colorWithRed:157 green:152 blue:149] CGColor];
    previewWebView.layer.borderWidth = 1.0f;
    self.previewWebView = previewWebView;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidesWhenStopped = YES;
    self.spinner = spinner;

    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.backgroundView = nil;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 61.0f;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.scrollEnabled = NO;
    tableView.allowsSelection = NO;
    tableView.contentInset = UIEdgeInsetsZero;
    self.tableView = tableView;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [scrollView addSubview:tableView];
    [scrollView addSubview:previewWebView];
    [scrollView addSubview:spinner];
    self.scrollView = scrollView;

    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor whiteColor];
    [view addSubview:previewWebViewHeaderImageView];
    [view addSubview:scrollView];
    self.view = view;
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        _keyboardShowing = NO;
        self.tableView.dataSource = nil;
        self.tableView.delegate = nil;
        self.previewWebView.delegate = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    bounds = CGRectInset(bounds, kDQWebProfileShareInset, kDQWebProfileShareInset);
    
    self.previewWebViewHeaderImageView.frameOrigin = CGPointMake(bounds.origin.x, bounds.origin.y + 40.0f);
    self.previewWebView.frame = CGRectMake(bounds.origin.x, self.previewWebViewHeaderImageView.frameMaxY - 3.0f, self.previewWebViewHeaderImageView.frameWidth, 270.0f);
    self.scrollView.contentSize = bounds.size;
    self.tableView.frame = CGRectMake(bounds.origin.x, CGRectGetMaxY(self.previewWebView.frame) + 20.0f, CGRectGetWidth(bounds), CGRectGetHeight(bounds) - self.previewWebView.frameHeight + 3.0f);
    self.spinner.center = self.previewWebView.center;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = DQLocalizedString(@"Share Your Profile!", @"Prompt to share the user's web profile with others");

    UINib *shareCellNib = [UINib nibWithNibName:@"DQShareWebProfileCell" bundle:nil];
    UINib *messageCellNib = [UINib nibWithNibName:@"DQSocialNetworkMessageCell" bundle:nil];
    [self.tableView registerNib:shareCellNib forCellReuseIdentifier:@"DQShareWebProfileCell"];
    [self.tableView registerNib:messageCellNib forCellReuseIdentifier:@"SocialNetworkMessageCell"];

    NSString *urlString = [[NSBundle mainBundle] objectForInfoDictionaryKey:DQWebProfileSharePreviewURLStringKey];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request addValue:[self.loggedInAccount authTokenForSource:@"web-profile-share"] forHTTPHeaderField:DQAPIHeaderSessionID];
    [self.previewWebView loadRequest:request];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    self.loggedInAccount.shouldShowShareWebProfile = NO;
    [self.privateServiceController requestSetSawWebProfileModalWithFailureBlock:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification*)notification
{
    if (!_keyboardShowing)
    {
        _keyboardShowing = YES;
        CGFloat bottomInset = 768 - CGRectGetHeight(self.view.frame);
        self.scrollView.contentInset = (UIEdgeInsets){ .top = 0, .left = 0, .right = 0, .bottom = bottomInset };
        CGPoint contentOffset = self.scrollView.contentOffset;
        contentOffset.y += bottomInset;
        [self.scrollView setContentOffset:contentOffset animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if(_keyboardShowing)
    {
        _keyboardShowing = NO;
        self.scrollView.contentInset = UIEdgeInsetsZero;
        [self.scrollView setContentOffset:CGPointZero animated:YES];
    }
}

#pragma mark - Tableview data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sharing ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return [self shareWebProfileCellForTableView:tableView];
    else if (indexPath.section == 1)
        return [self shareSharingTextCellForTableView:tableView];
    return nil;
}

- (DQShareWebProfileCell *)shareWebProfileCellForTableView:(UITableView *)tableView
{
    static NSString *identifier = @"DQShareWebProfileCell";
    DQShareWebProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    cell.title = DQLocalizedString(@"Web Profile", @"Label for the user's web profile");
    cell.sharing = self.sharing;
    __weak typeof(self) weakSelf = self;
    __weak typeof(self.view) weakView = self.view;
    __weak typeof(cell) weakCell = cell;
    cell.sharingBlock = ^(DQShareWebProfileCell *c, BOOL sharing) {
        weakSelf.sharing = sharing;
        [weakSelf.privateServiceController requestWebProfilePrivacyChange:(!sharing) completionBlock:^(DQHTTPRequest *request, id JSONObject) {
            weakSelf.loggedInAccount.webProfileEnabled = sharing;
            if (weakSelf && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
            {
                if ( ! (request && JSONObject))
                {
                    weakCell.sharing = !sharing;
                }
            }
        } failureBlock:^(DQHTTPRequest *request) {
            if (weakSelf && [weakSelf isViewLoaded] && (weakSelf.view == weakView))
            {
                weakCell.sharing = !sharing;
            }
        }];
    };
    return cell;
}

- (UITableViewCell *)shareSharingTextCellForTableView:(UITableView *)tableView
{
    static NSString *identifier = @"SocialNetworkMessageCell";
    DQSocialNetworkMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    cell.profileURL = [self profileURLForCurrentUser];
    __weak typeof(self) weakSelf = self;
    self.shareMessage = cell.messageText;
    cell.messageChangedBlock = ^(NSString *text) {
        weakSelf.shareMessage = text;
    };
    return cell;
}

- (NSURL *)profileURLForCurrentUser
{
    NSString *urlString = @"http://example.com/";
    if (self.loggedInAccount.username)
    {
        urlString = [urlString stringByAppendingString:self.loggedInAccount.username];
    }
    return [NSURL URLWithString:urlString];
}

#pragma mark - TableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 1) ? 83.0f : 61.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return (section == 1) ? 61.0f : 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        UINib *buttonHeaderViewNib = [UINib nibWithNibName:@"DQSocialNetworkButtonHeaderView" bundle:nil];
        DQSocialNetworkButtonHeaderView* headerView = [[buttonHeaderViewNib instantiateWithOwner:nil options:nil] lastObject];
        __weak typeof(self) weakSelf = self;

        headerView.title = DQLocalizedString(@"Share Your Profile", @"Prompt to share the user's web profile with others");
        
        [self.twitterController hasTwitterAccess:^(BOOL access) {
            headerView.twitterSharing = access;
            self.shareOnTwitter = access;
        } failureBlock:^(NSError *error) {
            DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Twitter Auth Error", @"Twitter authorization error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
            [alertView show];
            headerView.twitterSharing = NO;
            self.shareOnTwitter = NO;
        }];

        BOOL hasFacebookSharingPermissions = [self.facebookController hasOpenFacebookSessionWithPermissions:@[@"publish_actions" ]];
        headerView.facebookSharing = hasFacebookSharingPermissions;
        self.shareOnFacebook = hasFacebookSharingPermissions;

        self.twitterAuthRequestSourceView = headerView.twitterButton;
        
        headerView.valueChangedBlock = ^(DQSocialNetworkButtonHeaderView *c, BOOL facebook, BOOL twitter) {
            if (facebook)
            {
                if ([weakSelf.facebookController hasOpenFacebookSessionWithPermissions:@[@"publish_actions" ]])
                    weakSelf.shareOnFacebook = YES;
                else
                {
                    c.facebookButton.enabled = NO;
                    [weakSelf.facebookController requestFacebookPublishAccessFromViewController:weakSelf feature:@"share-web-profile" cancellationBlock:^{
                        // Revert button state
                        c.facebookButton.enabled = YES;
                        c.facebookSharing = ! c.facebookSharing;
                    } completionBlock:^(NSString *facebookToken) {
                        c.facebookButton.enabled = YES;
                        weakSelf.shareOnFacebook = YES;
                        c.facebookSharing = YES;
                    } failureBlock:^(NSError *error) {
                        c.facebookButton.enabled = YES;
                        DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Facebook Error", @"Facebook error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                        [alertView show];
                        weakSelf.shareOnFacebook = NO;
                        c.facebookSharing = NO;
                    }];
                }
            }
            else
            {
                weakSelf.shareOnFacebook = NO;
                c.facebookSharing = NO;
            }
            
            if (twitter)
            {
                [weakSelf.twitterController hasTwitterAccess:^(BOOL access) {
                    if (access)
                    {
                        weakSelf.shareOnTwitter = YES;
                        c.twitterSharing = YES;
                    }
                    else
                    {
                        c.twitterButton.enabled = NO;
                        [weakSelf requestTwitterAccessInView:self.twitterAuthRequestSourceView withCancellationBlock:^{
                            // Revert button state
                            c.twitterButton.enabled = YES;
                            c.twitterSharing = ! c.twitterSharing;
                        } accountSelectedBlock:^{
                            // Do nothing here
                        } completionBlock:^{
                            c.twitterButton.enabled = YES;
                            weakSelf.shareOnTwitter = YES;
                            c.twitterSharing = YES;
                        } failureBlock:^(NSError *error) {
                            c.twitterButton.enabled = YES;
                            DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Twitter Error", @"Twitter error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                            [alertView show];
                            weakSelf.shareOnTwitter = NO;
                            c.twitterSharing = NO;
                        }];
                    }
                } failureBlock:^(NSError *error) {
                    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Twitter Auth Error", @"Twitter authorization error alert title") message:error.dq_displayDescription delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleOK", nil, nil, @"OK", @"OK button for alert view") otherButtonTitles:nil];
                    [alertView show];
                    weakSelf.shareOnTwitter = NO;
                    c.twitterSharing = NO;
                }];
            }
            else
            {
                weakSelf.shareOnTwitter = NO;
                c.twitterSharing = NO;
            }
        };

        return headerView;
    }

    return nil;
}

#pragma mark - Webview delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.spinner stopAnimating];
    if (error != nil)
        TWDLog(@"error = %@", error);
}

#pragma mark - Accessors

- (void)setSharing:(BOOL)sharing
{
    [self willChangeValueForKey:@"sharing"];
    _sharing = sharing;
    [self.tableView reloadData];
    [self didChangeValueForKey:@"sharing"];
}

@end
