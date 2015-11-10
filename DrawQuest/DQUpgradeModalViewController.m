//
//  DQUpgradeModalViewController.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-05.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQUpgradeModalViewController.h"
#import "UIButton+DQAdditions.h"
#import "UIView+STAdditions.h"

static NSString *const DQUpgradeModalURLString = @"https://example.com/app/upgrade";

@interface DQUpgradeModalViewController () <UIWebViewDelegate>
@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) UIActivityIndicatorView *spinner;
@end

@implementation DQUpgradeModalViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    if ((self = [super initWithDelegate:delegate]))
    {
        self.title = DQLocalizedString(@"DrawQuest Update Available!", @"Update for DrawQuest app is available indicator label");
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor whiteColor];

    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.delegate = self;
    [view addSubview:webView];
    self.webView = webView;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidesWhenStopped = YES;
    [view addSubview:spinner];
    self.spinner = spinner;
    self.view = view;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.spinner.center = self.webView.center;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:DQUpgradeModalURLString]];
    [self.webView loadRequest:request];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.webView.delegate = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
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

@end
