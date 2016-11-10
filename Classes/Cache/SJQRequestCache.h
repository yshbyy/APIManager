//
//  SJQRequestCache.h
//  SheJiQuan
//
//  Created by yshbyy on 15/11/12.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//


/*!
 @header SJQRequestCache.h
 @abstract API接口缓存管理者
 @author yshbyy
 */

#import <Foundation/Foundation.h>

@class SJQCacheObject;

//获取缓存回调
typedef void(^SJQCacheObjectComplitionHandle)(SJQCacheObject *cacheObject);

/**
 请求数据缓存管理
 将URL当做缓存存储的key来进行缓存，缓存通过归档方式进行。
 */
@interface SJQRequestCache : NSObject

/*!
 @brief 单例
 @return 缓存管理者单例
 */
+ (instancetype)shareCache;

/*!
 *  @brief 文件存储路径
 *  @return 路径URL
 */
- (NSURL *)diskCachePath;

/*!
 *  @brief  根据request从获取缓存，先从内存中查找，没有就从硬盘查找，查不到的话completionBlock回调nil（找到回调缓存）
 *
 *  @param request    request
 *  @param complition 获取完成回调
 *
 */
- (void)cacheWithRequest:(NSURLRequest *)request complitionHandle:(SJQCacheObjectComplitionHandle)complition;

/*!
 *  @brief  缓存请求，将请求缓存在本地
 *
 *  @param response     响应
 *  @param responseData 响应数据
 *  @param request      请求
 *
 */
- (void)saveCacheWithResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responseData forRequest:(NSURLRequest *)request;
/*!
 @brief 移除对应请求的缓存
 @param request 请求
 */
- (void)removeCacheWithRequest:(NSURLRequest *)request;
@end
