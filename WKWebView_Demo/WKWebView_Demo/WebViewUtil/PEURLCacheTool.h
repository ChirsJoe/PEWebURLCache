//
//  PEURLCacheTool.h
//  PencialEnglish
//
//  Created by Joe on 2018/9/20.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PEURLCacheTool : NSObject

+ (BOOL)cachePossibleWithURLString:(NSString *)string;

+ (void)saveData:(NSData *)data forURL:(NSString *)url;

+ (NSData *)cacheDataWithURLString:(NSString *)url;

+ (void)deleteWebURLCache;

+ (CGFloat)readWebURLCacheSize;


+ (NSString *)getMIMETypeWithCAPIWiithURLString:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
