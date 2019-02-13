//
//  PEURLSession.h
//  PencialEnglish
//
//  Created by Joe on 2018/9/17.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEURLSession : NSObject

+ (PEURLSession *)sharedSession;

/*! Create a demultiplex for the specified session configuration.
 *  \param configuration The session configuration to use; if nil, a default session is created.
 *  \returns An initialised instance.
 */

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration;

@property (atomic, copy,   readonly ) NSURLSessionConfiguration *   configuration;  ///< A copy of the configuration passed to -initWithConfiguration:.
@property (atomic, strong, readonly ) NSURLSession *                session;        ///< The session created from the configuration passed to -initWithConfiguration:.

/*! Creates a new data task whose delegate callbacks are routed to the supplied delegate.
 *  \details The callbacks are run on the current thread (that is, the thread that called this
 *  method) in the specified modes.
 *
 *  The delegate is retained until the task completes, that is, until after your
 *  -URLSession:task:didCompleteWithError: delegate callback returns.
 *
 *  The returned task is suspend.  You must resume the returned task for the task to
 *  make progress.  Furthermore, it's not safe to simply discard the returned task
 *  because in that case the task's delegate is never released.
 *
 *  \param request The request that the data task executes; must not be nil.
 *  \param delegate The delegate to receive the data task's delegate callbacks; must not be nil.
 *  \param modes The run loop modes in which to run the data task's delegate callbacks; if nil or
 *  empty, the default run loop mode (NSDefaultRunLoopMode is used).
 *  \returns A suspended data task that you must resume.
 */

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request delegate:(id<NSURLSessionDataDelegate>)delegate modes:(NSArray *)modes;
@end
