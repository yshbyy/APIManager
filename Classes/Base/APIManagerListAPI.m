//
//  APIManagerListAPI.m
//  SheJiQuan
//
//  Created by yshbyy on 16/4/13.
//  Copyright © 2016年 BaoliNetworkTechnology. All rights reserved.
//

#import "APIManagerListAPI.h"

@implementation APIManagerListAPI
- (instancetype)initWithReformer:(id<APIManagerResponseDataReformer>)reformer {
    if (self = [super initWithReformer:reformer]) {
        self.loadCacheDataFist = NO;
    }
    return self;
}
#pragma mark - Method
- (void)refreshLoad {
    self.loadCacheDataFist = NO;
    _pageIndex = 1;
    [self startLoadding];
}
- (void)loadNextPage {
    self.loadCacheDataFist = NO;
    _pageIndex++;
    [self startLoadding];
}

#pragma mark - getter && setter

- (void)setPageIndex:(NSInteger)pageIndex {
    if (pageIndex < 1) {
        pageIndex = 1;
    }
    _pageIndex = pageIndex;
}

- (NSInteger)pageSize {
    return 15;
}

#pragma mark - APIManager
- (NSString *)apiManagerRequestPath {
    return @"";
}
- (NSString *)apiManagerRequestMethod {
    return kAPIManagerRequestMethodGET;
}
- (void)apiManagerDidFailure {
    self.pageIndex-- ;
}
@end
