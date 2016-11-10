//
//  SJQNetworkReachability.h
//  SheJiQuan
//
//  Created by yshbyy on 16/5/26.
//  Copyright © 2016年 BaoliNetworkTechnology. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

extern AFNetworkReachabilityStatus kSJQNetworkReachabilityStatus;/**< 当前网络状态 */
extern BOOL kSJQNetworkReachable;/**< 是否联网 */

/**
 网络状态监测，利用AFNetworking
 */
@interface SJQNetworkReachability : NSObject

/*!
 @brief 开始监控
 */
+ (void)startWorking;

@end
