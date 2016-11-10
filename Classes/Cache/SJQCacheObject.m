//
//  SJQCacheObject.m
//  SheJiQuan
//
//  Created by yshbyy on 15/11/12.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//

#import "SJQCacheObject.h"

@implementation SJQCacheObject

- (id)copyWithZone:(NSZone *)zone {
    SJQCacheObject *cacheObj = [[SJQCacheObject allocWithZone:zone] init];
    cacheObj.responseData = [self.responseData copy];
    cacheObj.response = [self.response copy];
    return cacheObj;
}
+ (instancetype)cacheWithResponse:(NSHTTPURLResponse *)response responseData:(NSData *)responsData {
    SJQCacheObject *cacheObject = [[SJQCacheObject alloc] init];
    cacheObject.responseData = responsData;
    cacheObject.response = response;
    return cacheObject;
}

#pragma mark - secureCoding
+ (BOOL)supportsSecureCoding {
    return YES;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.response = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(response))];
        self.responseData = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(responseData))];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
    [aCoder encodeObject:self.responseData forKey:NSStringFromSelector(@selector(responseData))];
}
@end
