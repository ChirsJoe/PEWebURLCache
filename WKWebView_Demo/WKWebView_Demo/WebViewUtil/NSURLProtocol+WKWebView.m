//
//  NSURLProtocol+WKWebView.m
//  PencialEnglish
//
//  Created by Joe on 2018/9/17.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import "NSURLProtocol+WKWebView.h"
#import <WebKit/WebKit.h>
//FOUNDATION_STATIC_INLINE 属于属于runtime范畴，你的.m文件需要频繁调用一个函数,可以用static inline来声明。从SDWebImage从get到的。
FOUNDATION_STATIC_INLINE Class ContextControllerClass() {
    static Class cls;
    if (!cls) {
        cls = [[[WKWebView new] valueForKey:@"browsingContextController"] class];
    }
    return cls;
}

FOUNDATION_STATIC_INLINE SEL RegisterSchemeSelector() {
    return NSSelectorFromString(@"registerSchemeForCustomProtocol:");
}

FOUNDATION_STATIC_INLINE SEL UnregisterSchemeSelector() {
    return NSSelectorFromString(@"unregisterSchemeForCustomProtocol:");
}

@implementation NSURLProtocol (WKWebView)

+ (void)wk_registerScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = RegisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
        // 放弃编辑器警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

+ (void)wk_unregisterScheme:(NSString *)scheme {
    Class cls = ContextControllerClass();
    SEL sel = UnregisterSchemeSelector();
    if ([(id)cls respondsToSelector:sel]) {
        // 放弃编辑器警告
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [(id)cls performSelector:sel withObject:scheme];
#pragma clang diagnostic pop
    }
}

@end
