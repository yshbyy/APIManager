//
//  SJQRequestCache.m
//  SheJiQuan
//
//  Created by yshbyy on 15/11/12.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//

#import "SJQRequestCache.h"
#import "SJQCacheObject.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

static const NSUInteger kMaxCacheAge = 2/*h*/ * 60/*m*/ * 60/*s*/;//2小时
static const NSUInteger kMemoryCountLimit = 3;

@interface SJQRequestCache ()
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSCache<NSString *, SJQCacheObject *> *memoryCaches;
@end

@implementation SJQRequestCache

#pragma mark - 生命周期
- (instancetype)init {
    if (self = [super init]) {
        _ioQueue = dispatch_queue_create("shejiquan.urlCache.backgoundIOQueue", DISPATCH_QUEUE_SERIAL);
        _fileManager = [NSFileManager defaultManager];
        _memoryCaches = [[NSCache alloc] init];
        _memoryCaches.countLimit = kMemoryCountLimit;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundCleanDisk) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanDisk) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}
+ (instancetype)shareCache {
    static SJQRequestCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[SJQRequestCache alloc] init];
    });
    return cache;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - 数据存储路径
- (NSURL *)diskCachePath {
    //沙盒路径（Library/Caches）
    NSURL *sandBoxCachePath = [[self.fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
    sandBoxCachePath = [sandBoxCachePath URLByAppendingPathComponent:@"shejiquanAPICaches"];
    if (![self.fileManager fileExistsAtPath:sandBoxCachePath.path]) {
        [self.fileManager createDirectoryAtPath:sandBoxCachePath.path withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return sandBoxCachePath;
}
- (NSURL *)fileFullPathForKey:(NSString *)key {
    return [[self diskCachePath] URLByAppendingPathComponent:key];
}

+ (NSString *)keyWithURL:(NSURL *)url {
        const char *cString = [url.absoluteString UTF8String];
        
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        
        CC_MD5(cString, (int)strlen(cString), result);
        
        return [
                
                NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                
                result[0],result[1],result[2],result[3],
                
                result[4],result[5],result[6],result[7],
                
                result[8],result[9],result[10],result[11],
                
                result[12],result[13],result[14],result[15]
                
                ];
}
#pragma mark - 数据存取
//根据request返回缓存数据
- (void)cacheWithRequest:(NSURLRequest *)request complitionHandle:(SJQCacheObjectComplitionHandle)complition {
    //cacheKey
    NSString *cacheKey = [SJQRequestCache keyWithURL:request.URL];
    //首先从内存缓存中读取
    SJQCacheObject *cacheObject = [self cacheFromMemoryForKey:cacheKey];
    if (cacheObject != nil) {
        if (complition) {
            complition(cacheObject);
        }
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(_ioQueue, ^{
       
        __strong typeof(weakSelf) strongSelf = weakSelf;
        SJQCacheObject *cacheObject = [strongSelf cacheFromDiskForKey:cacheKey];
        if (complition) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                complition(cacheObject);
            });
        }
    });
}
//从内存中查找缓存
- (SJQCacheObject *)cacheFromMemoryForKey:(NSString *)cacheKey {
    return [_memoryCaches objectForKey:cacheKey];
}
//从硬盘查找缓存
- (SJQCacheObject *)cacheFromDiskForKey:(NSString *)cacheKey {
    NSURL *fileUrl = [self fileFullPathForKey:cacheKey];
    if (![self.fileManager fileExistsAtPath:fileUrl.path]) {
        return nil;
    }
    if ([self overdueForFileURL:fileUrl]) {
        NSError *error;
        [self.fileManager removeItemAtPath:fileUrl.path error:&error];
        return nil;
    }
    SJQCacheObject *cacheObject = [NSKeyedUnarchiver unarchiveObjectWithFile:[self fileFullPathForKey:cacheKey].path];
    if (cacheObject) {
        [_memoryCaches setObject:cacheObject forKey:cacheKey];
    }
    return cacheObject;
}
- (void)saveCacheWithResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responseData forRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;
    NSString *cacheKey = [SJQRequestCache keyWithURL:request.URL];
    
    SJQCacheObject *cacheObject = [SJQCacheObject cacheWithResponse:response responseData:responseData];
    //先存入内存中
    if (![_memoryCaches objectForKey:cacheKey]) {
        [_memoryCaches setObject:cacheObject forKey:cacheKey];
    }
    
    //在子线程异步执行缓存操作，NSFileManager是线程安全的，so不需考虑多线程的数据安全问题
    //存入硬盘
    dispatch_async(_ioQueue, ^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSString *filePath = [strongSelf fileFullPathForKey:cacheKey].path;
        
        //如果硬盘没有，直接存入
        if (![strongSelf.fileManager fileExistsAtPath:filePath]) {
            [NSKeyedArchiver archiveRootObject:cacheObject toFile:filePath];
            return ;
        }
        
        //如果硬盘有，就判断文件是否过期，过期则重新写入
        NSURL *fileURL = [NSURL URLWithString:filePath];
        if ([self overdueForFileURL:fileURL]) {
            NSError *error = nil;
            [_fileManager removeItemAtPath:filePath error:&error];
            [NSKeyedArchiver archiveRootObject:cacheObject toFile:filePath];
        }
    });
}

- (BOOL)overdueForFileURL:(NSURL *)fileURL {
    NSError *error = nil;
    NSDictionary *resourceValues = [fileURL resourceValuesForKeys:@[NSURLContentModificationDateKey] error:&error];
    NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
    NSDate *overdueDate = [NSDate dateWithTimeIntervalSinceNow:-(NSInteger)kMaxCacheAge];
    
    if ([[overdueDate laterDate:modificationDate] isEqualToDate:overdueDate]) {//如果缓存过期
        return YES;
    }
    return NO;
}
#pragma mark - 清除缓存
//内存警告时，清除内存缓存
- (void)cleanMemory {
    [_memoryCaches removeAllObjects];
}
//当进入后台时，清除过期缓存
- (void)backgroundCleanDisk {
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    [self cleanDiskWithComplitionBlock:^{
        
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];
}
//程序终止时清理磁盘过期缓存
- (void)cleanDisk {
    [self cleanDiskWithComplitionBlock:nil];
}
//清除所有磁盘过期缓存
- (void)cleanDiskWithComplitionBlock:(void(^)())complition {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.ioQueue, ^{
        
        NSURL *diskCacheURL = [NSURL fileURLWithPath:[self diskCachePath].path isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        for (NSURL *fileURL in fileEnumerator) {
            if ([weakSelf overdueForFileURL:fileURL]) {
                [_fileManager removeItemAtURL:fileURL error:nil];
            }
        }
        if (complition) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complition();
            });
        }
    });
}
- (void)removeCacheWithRequest:(NSURLRequest *)request {
    NSURL *fileURL = [self fileFullPathForKey:[SJQRequestCache keyWithURL:request.URL]];
    [_fileManager removeItemAtURL:fileURL error:nil];
}
@end
