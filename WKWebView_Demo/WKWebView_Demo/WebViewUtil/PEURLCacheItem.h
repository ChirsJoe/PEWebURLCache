//
//  PEURLCacheItem.h
//  PencialEnglish
//
//  Created by Joe on 2018/9/20.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import "PEObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface PEURLCacheItem : PEObject
@property(nonatomic, copy) NSString *originalUrl;
@property(nonatomic, copy) NSString *dataString;
@property(nonatomic, copy) NSString *mimeType;
@property(nonatomic, strong) NSData *data;

@end

NS_ASSUME_NONNULL_END
