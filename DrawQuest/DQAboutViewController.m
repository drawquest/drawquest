//
//  DQAboutViewController.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/17/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQAboutViewController.h"
#import "DQAnalyticsConstants.h"
#import "DQAbstractServiceController.h"

@interface DQAboutViewController ()

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation DQAboutViewController

- (id)initWithDelegate:(id<DQViewControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (!self) {
        return nil;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        self.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    NSString *buildInfo = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"DQBuildInfo"];
    NSString *title = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([buildInfo length])
        {
            title = [DQLocalizedString(@"About DrawQuest", @"Navigation title for about us modal") stringByAppendingFormat:@" %@ (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], buildInfo];
        }
        else
        {
            title = [DQLocalizedString(@"About DrawQuest", @"Navigation title for about us modal") stringByAppendingFormat:@" %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        }
    }
    else
    {
        title = DQLocalizedString(@"About", @"Navigation title for about us modal, shortened for iPhone");
    }
    self.title = title;

    return self;
}


#pragma mark - UIViewController

- (void)loadView
{
    self.webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    self.view = self.webView;
    
    self.webView.scalesPageToFit = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *urlString = [[self settingForKey:DQRouterSpecifiedWebURL fallbackKey:DQServiceControllerDefaultWebEndpointInfoDictKey] stringByAppendingString:@"app/about"];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        urlString = [urlString stringByAppendingString:@"?idiom=iPad"];
    }
    else
    {
        urlString = [urlString stringByAppendingString:@"?idiom=iPhone"];
    }

    NSURLRequest *aboutURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.webView loadRequest:aboutURLRequest];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewAbout withParameters:nil];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
