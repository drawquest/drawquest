//
//  DQTumblrShareViewController.m
//  DrawQuest
//
//  Created by David Mauro on 4/2/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTumblrShareViewController.h"
#import "DQAnalyticsConstants.h"

@interface DQTumblrShareViewController () <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSString *tumblrSuccessRegexPattern;

@end

@implementation DQTumblrShareViewController

- (id)initWithPhotoURL:(NSString *)sharePhotoURL clickThruURL:(NSString *)shareLinkURL caption:(NSString *)shareCaption tags:(NSString *)shareTags tumblrSuccessRegexPattern:(NSString *)tumblrSuccessRegexPattern
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _tumblrSuccessRegexPattern = tumblrSuccessRegexPattern;
        
        // URL Encode strings
        sharePhotoURL = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)(sharePhotoURL), NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8));
        shareLinkURL = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)(shareLinkURL), NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8));
        shareCaption = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)(shareCaption), NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8));
        shareTags = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)(shareTags), NULL, CFSTR("!*'();:@&=+@,/?#[]"), kCFStringEncodingUTF8));
        
        NSString *shareString = [NSString stringWithFormat:@"http://www.tumblr.com/share/photo?source=%@&click_thru=%@&caption=%@&tags=%@", sharePhotoURL, shareLinkURL, shareCaption, shareTags];
        NSURLRequest *tumblrShareRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:shareString]];
        self.webView = [[UIWebView alloc] init];
        self.webView.delegate = self;
        [self.webView loadRequest:tumblrShareRequest];
    }
    return self;
}

#pragma mark - UIViewController

- (void)loadView
{
    self.view = self.webView;
    self.navigationItem.hidesBackButton = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

#pragma mark -
#pragma mark UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Dimissal hack:
    // Watch for "Done!" between two tags in the body to dismiss share view
    NSString *matchString = self.tumblrSuccessRegexPattern;
    NSString *html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:matchString options:NSRegularExpressionCaseInsensitive error:nil];
    if ([[regEx matchesInString:html options:0 range:NSMakeRange(0, [html length])] count] > 0)
    {
        [self dismissViewControllerAnimated:YES completion:nil]; // FIXME: dismissal is not its own responsibility
        if (self.shareSuccessBlock)
        {
            self.shareSuccessBlock(self);
        }
    }
}

@end
