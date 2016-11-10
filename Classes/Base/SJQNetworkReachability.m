//
//  SJQNetworkReachability.m
//  SheJiQuan
//
//  Created by yshbyy on 16/5/26.
//  Copyright © 2016年 BaoliNetworkTechnology. All rights reserved.
//

#import "SJQNetworkReachability.h"

AFNetworkReachabilityStatus kSJQNetworkReachabilityStatus = AFNetworkReachabilityStatusUnknown;
BOOL kSJQNetworkReachable = YES;

@implementation SJQNetworkReachability

+ (void)startWorking {
    AFNetworkReachabilityManager *reachability = [AFNetworkReachabilityManager sharedManager];
    [reachability setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        kSJQNetworkReachabilityStatus = status;
        if ((status != AFNetworkReachabilityStatusUnknown) && (status != AFNetworkReachabilityStatusNotReachable)) {
            kSJQNetworkReachable = YES;
        } else {
            kSJQNetworkReachable = NO;
        }
    }];
    [reachability startMonitoring];
}

@end
