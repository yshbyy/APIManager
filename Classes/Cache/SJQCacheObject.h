//
//  SJQCacheObject.h
//  SheJiQuan
//
//  Created by yshbyy on 15/11/12.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//

/*!
 @header SJQCacheObject.h
 @abstract API接口缓存数据对象
 @author yshbyy
 */

#import <Foundation/Foundation.h>

/**
 API接口缓存
 */
@interface SJQCacheObject : NSObject<NSSecureCoding,NSCopying>

/*!
 @brief 请求响应体
 */
@property (nonatomic, strong) NSHTTPURLResponse *response;
/*!
 @brief 返回数据
 */
@property (nonatomic, strong) NSData *responseData;

/*!
 @brief 快速创建方法
 @param response    响应
 @param responsData 返回数据
 @return 缓存
 */
+ (instancetype)cacheWithResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responsData;
@end
