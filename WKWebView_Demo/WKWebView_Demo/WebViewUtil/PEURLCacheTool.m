//
//  PEURLCacheTool.m
//  PencialEnglish
//
//  Created by Joe on 2018/9/20.
//  Copyright © 2018年 Joe. All rights reserved.
//

#import "PEURLCacheTool.h"
#import <CommonCrypto/CommonCrypto.h>
#import <MobileCoreServices/MobileCoreServices.h>
static NSString *const PEWebCacheName = @"PEWebCache";


@implementation PEURLCacheTool

#pragma mark - CachePath

+ (void)createDirectoryAtPath:(NSString *)path {
    BOOL isDir = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    if (isExist) {
        if (!isDir) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
    } else {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (NSString *)basePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains (NSCachesDirectory , NSUserDomainMask , YES) firstObject];
    return cachePath;
}

+ (NSString *)webCachePath {
    return [[self basePath] stringByAppendingPathComponent:PEWebCacheName];
}

+ (NSString *)cacheKeyForURL:(NSString *)url {
    return [self md5:url];
}

+ (void)saveData:(NSData *)data forURL:(NSString *)url {
    if ([self cacheExistsWithURLString:url]) {
        return;
    }
    NSError *error = nil;
    NSString *path = [self webCachePath];
    [self createDirectoryAtPath:path];

    NSString *filePath = [self filePathWithURLString:url];
    
    [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
    if (error) {
        DEBUGLog(@"写入失败-------------：%@",error);
    }
}

+ (NSData *)cacheDataWithURLString:(NSString *)url {
    if (![self cacheExistsWithURLString:url]) {
        return nil;
    }
    NSString *filePath = [self filePathWithURLString:url];
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    return data;
}

+ (BOOL)cacheExistsWithURLString:(NSString *)url {

    NSString *filePath = [self filePathWithURLString:url];
    
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return result;
}

+ (void)deleteWebURLCache {
    NSString *path = [self webCachePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}


+ (CGFloat)readWebURLCacheSize {
    NSString *path = [self webCachePath];
    unsigned long long folderSize = [self fileSizeAtPath:path];
    CGFloat size = folderSize/( 1024.0 * 1024.0);
    if (size < 0.1) {
        size = 0;
    }
    return size;
}

+ (NSString *)filePathWithURLString:(NSString *)url {
    
    NSString *path = [self webCachePath];
    
    NSString *fileName = [self fileNameWithURLString:url];
    
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}

+ (NSString *)fileNameWithURLString:(NSString *)url {
    NSString *formatURL = [self formatURLString:url];
    NSString *key = [self cacheKeyForURL:formatURL];
    NSString *fileName = [key stringByAppendingPathExtension:formatURL.pathExtension];
    return fileName;
}

+ (NSString *)md5:(NSString *)URLString
{
    const char * value = [URLString UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    NSMutableString * outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
    {
        [outputString appendFormat:@"%02x", outputBuffer[count]];
    }
    return outputString;
}


+ (BOOL)cachePossibleWithURLString:(NSString *)string {
    if ([string containsString:@".png"]) {
        return YES;
    }else if ([string containsString:@".jpg"]) {
        return YES;
    }else if ([string containsString:@".gif"]) {
        return YES;
    }else if ([string containsString:@".css"]) {
        return YES;
    }
    return NO;
}

+ (NSString *)formatURLString:(NSString *)original {
    NSString *seq = @"?";
    if ([original containsString:seq]) {
        original = [[original componentsSeparatedByString:seq] objectAtIndex:0];
    }
    return original;
}

+ (NSString *)getMIMETypeWithCAPIWiithURLString:(NSString *)url
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[url pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!MIMEType) {
        return @"application/octet-stream";
    }
    return (__bridge NSString *)(MIMEType);
}


+ (unsigned long long)fileSizeAtPath:(NSString *) filePath{
    NSFileManager * manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath :filePath]){
        return [[manager attributesOfItemAtPath :filePath error : nil] fileSize];
    }
    return 0;
}
@end
