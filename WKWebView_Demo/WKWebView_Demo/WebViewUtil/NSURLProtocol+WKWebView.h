//
//  NSURLProtocol+WKWebView.h
//  PencialEnglish
//
//  Created by Joe on 2018/9/17.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLProtocol (WKWebView)

+ (void)wk_registerScheme:(NSString*)scheme;

+ (void)wk_unregisterScheme:(NSString*)scheme;

@end
