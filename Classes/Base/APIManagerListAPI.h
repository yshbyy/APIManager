//
//  APIManagerListAPI.h
//  SheJiQuan
//
//  Created by yshbyy on 16/4/13.
//  Copyright © 2016年 BaoliNetworkTechnology. All rights reserved.
//

#import "SJQBaseAPIManager.h"

/**
 需要分页的API基类
 */
@interface APIManagerListAPI : SJQBaseAPIManager<APIManager>

/**
 当前页
 */
@property (nonatomic, assign) NSInteger pageIndex;

/**
 每页条数
 */
@property (nonatomic, assign, readonly) NSInteger pageSize;

/**
 刷新，即把 pageIndex 置为 1 后发送请求
 */
- (void)refreshLoad;

/**
 加载下一页，即 pageIndex++ 后再次发送请求
 */
- (void)loadNextPage;
@end
