//
//  PEURLProtocol.m
//  PencialEnglish
//
//  Created by Joe on 2018/9/17.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import "PEURLProtocol.h"
#import "PEURLSession.h"
#import "PECanonicalRequest.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "PEURLCacheTool.h"
static NSString* const KPEURLProtocolKey = @"KPEURLProtocolKey";
static NSString* const KPERegPrefix = @"https://res.qianbi360.com";

@interface PEURLProtocol ()<NSURLSessionDataDelegate>

@property (atomic, strong, readwrite) NSThread *                        clientThread;       ///< The thread on which we should call the client.
/*! The run loop modes in which to call the client.
 *  \details The concurrency control here is complex.  It's set up on the client
 *  thread in -startLoading and then never modified.  It is, however, read by code
 *  running on other threads (specifically the main thread), so we deallocate it in
 *  -dealloc rather than in -stopLoading.  We can be sure that it's not read before
 *  it's set up because the main thread code that reads it can only be called after
 *  -startLoading has started the connection running.
 */

@property (atomic, copy,   readwrite) NSArray *                         modes;

@property (atomic, strong, readwrite) NSURLSessionDataTask *            task;               ///< The NSURLSession task for that request; client thread only.

@property (atomic, strong) NSMutableData *responseData;
@end

@implementation PEURLProtocol

+ (void)startProxy {
    [NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request{

    NSString *scheme = [[request URL] scheme];
    if ( ([scheme caseInsensitiveCompare:@"http"]  == NSOrderedSame ||
          [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame ))
    {
        //NSString *str = request.URL.absoluteString;
        //看看是否已经处理过了，防止无限循环
        if ([NSURLProtocol propertyForKey:KPEURLProtocolKey inRequest:request])
            return NO;
        return YES;
    }
    return NO;
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {

    NSURLRequest *result = PECanonicalRequestForRequest(request);
    
    return result;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    
    NSMutableURLRequest *recursiveRequest = [[self request] mutableCopy];
    
    assert(recursiveRequest != nil);
    
    //给我们处理过的请求设置一个标识符, 防止无限循环,
    [NSURLProtocol setProperty:@YES forKey:KPEURLProtocolKey inRequest:recursiveRequest];
    
    NSURL *url = self.request.URL;
    NSData *data = [PEURLCacheTool cacheDataWithURLString:url.absoluteString];
    if (data) {
        NSString *mimeType = [PEURLCacheTool getMIMETypeWithCAPIWiithURLString:url.absoluteString];
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url MIMEType:mimeType expectedContentLength:data.length textEncodingName:nil];
        //4.响应
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }else{
        [self startRequest];
    }
}

- (void)stopLoading {
    
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
    }
}

- (void)startRequest {

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.task = [session dataTaskWithRequest:self.request];
    [self.task resume];
}


#pragma mark * Authentication challenge handling

/*! Performs the block on the specified thread in one of specified modes.
 *  \param thread The thread to target; nil implies the main thread.
 *  \param modes The modes to target; nil or an empty array gets you the default run loop mode.
 *  \param block The block to run.
 */

- (void)performOnThread:(NSThread *)thread modes:(NSArray *)modes block:(dispatch_block_t)block
{
    // thread may be nil
    // modes may be nil
    assert(block != nil);
    
    if (thread == nil) {
        thread = [NSThread mainThread];
    }
    if ([modes count] == 0) {
        modes = @[ NSDefaultRunLoopMode ];
    }
    [self performSelector:@selector(onThreadPerformBlock:) onThread:thread withObject:[block copy] waitUntilDone:NO modes:modes];
}

/*! A helper method used by -performOnThread:modes:block:. Runs in the specified context
 *  and simply calls the block.
 *  \param block The block to run.
 */

- (void)onThreadPerformBlock:(dispatch_block_t)block
{
    assert(block != nil);
    block();
}

#pragma mark - URLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSMutableURLRequest *    redirectRequest;
    
#pragma unused(session)
#pragma unused(task)
    assert(task == self.task);
    assert(response != nil);
    assert(newRequest != nil);
#pragma unused(completionHandler)
    assert(completionHandler != nil);
    assert([NSThread currentThread] == self.clientThread);
    
    // The new request was copied from our old request, so it has our magic property.  We actually
    // have to remove that so that, when the client starts the new request, we see it.  If we
    // don't do this then we never see the new request and thus don't get a chance to change
    // its caching behaviour.
    //
    // We also cancel our current connection because the client is going to start a new request for
    // us anyway.
    
    assert([[self class] propertyForKey:KPEURLProtocolKey inRequest:newRequest] != nil);
    
    redirectRequest = [newRequest mutableCopy];
    [[self class] removePropertyForKey:KPEURLProtocolKey inRequest:redirectRequest];
    
    // Tell the client about the redirect.
    
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    // Stop our load.  The CFNetwork infrastructure will create a new NSURLProtocol instance to run
    // the load of the redirect.
    
    // The following ends up calling -URLSession:task:didCompleteWithError: with NSURLErrorDomain / NSURLErrorCancelled,
    // which specificallys traps and ignores the error.
    
    [self.task cancel];
    
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    
    self.responseData = [[NSMutableData alloc] init];
    
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    NSString *url = self.request.URL.absoluteString;
    if ([PEURLCacheTool cachePossibleWithURLString:url]) {
        
        [self operateComplete];
    }
    if (!error) {
        [self.client URLProtocolDidFinishLoading:self];
    }else{
        [self.client URLProtocol:self didFailWithError:error];
    }
    
}

- (void)operateComplete {
    NSString *original = self.request.URL.absoluteString;
    /*
    NSString *seq = @"?";
    if ([original containsString:seq]) {
        original = [[original componentsSeparatedByString:seq] objectAtIndex:0];
    }
    NSString *mimeType = [self getMIMETypeWithPath:original];
    PEURLCacheItem *item = [[PEURLCacheItem alloc] init];
    item.originalUrl = original;
    item.dataString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    item.data = self.responseData;
    item.mimeType = mimeType;
    NSString *key = self.request.URL.absoluteString.md5String;
    YYCache *cache = [self pe_yycache];
    [cache setObject:item forKey:key];
    */
    [PEURLCacheTool saveData:self.responseData forURL:original];
}

#pragma mark - 拼接响应Response

- (NSHTTPURLResponse *)jointResponseWithData:(NSData *)data dataLength:(NSInteger)dataLength mimeType:(NSString *)mimeType requestUrl:(NSURL *)requestUrl statusCode:(NSInteger)statusCode httpVersion:(NSString *)httpVersion
{
    NSDictionary *dict = @{@"Content-type":mimeType,
                           @"Content-length":[NSString stringWithFormat:@"%ld",dataLength]};
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:requestUrl statusCode:statusCode HTTPVersion:httpVersion headerFields:dict];
    return response;
}


+ (NSString *)generateProxyPath:(NSString *) absoluteURL {
    NSString *tmpFilePath = NSTemporaryDirectory();
    NSString *fileAbsoluteURL = [@"file:/" stringByAppendingString:tmpFilePath];
    return [absoluteURL stringByReplacingOccurrencesOfString:KPERegPrefix
                                                  withString:fileAbsoluteURL];
}

+ (NSString *)generateDateReadPath:(NSString *) absoluteURL {
    NSString *fileDataReadURL = NSTemporaryDirectory();
    return [absoluteURL stringByReplacingOccurrencesOfString:KPERegPrefix
                                                  withString:fileDataReadURL];
}
@end
