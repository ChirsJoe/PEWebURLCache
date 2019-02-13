//
//  ViewController.m
//  WKWebView_Demo
//
//  Created by Joe on 2018/10/8.
//  Copyright © 2018 single. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "WebViewUtil/PEURLProtocol.h"
#import "WebViewUtil/NSURLProtocol+WKWebView.h"

NSString * const PEHttpScheme = @"http";
NSString * const PEHttpsScheme = @"https";
@interface ViewController ()<WKNavigationDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSURLProtocol wk_registerScheme:PEHttpScheme];
    [NSURLProtocol wk_registerScheme:PEHttpsScheme];
    [PEURLProtocol startProxy];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    webView.navigationDelegate = self;
    [self.view addSubview:webView];
    
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

@end
