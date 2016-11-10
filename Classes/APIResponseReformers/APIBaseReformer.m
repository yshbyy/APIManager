//
//  BaseReformer.m
//  SheJiQuan
//
//  Created by yshbyy on 15/11/13.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//

#import "APIBaseReformer.h"

@interface APIBaseReformer ()

@end

@implementation APIBaseReformer

- (id)apiManagerReformResponseData:(id)responseData {
//    if ([responseData objectForKey:@"data"] == nil)
//    {
//        return responseData;
//    }
    id resulteData = [self handledResponseObject:responseData];
    return resulteData;
}


- (NSDictionary *)handleDictionary:(NSDictionary *)dict
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
    
    NSMutableArray *keyToDeleteArray = [NSMutableArray array];
    NSMutableArray *subDictKeyArray = [NSMutableArray array];
    NSMutableArray *subArrayArray = [NSMutableArray array];
    [mutableDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        if (!*stop)
        {
            if ([obj isEqual:[NSNull null]])
            {
                [keyToDeleteArray addObject:key];
            }
            else if ([obj isKindOfClass:[NSDictionary class]])
            {
                [subDictKeyArray addObject:key];
            }
            else if ([obj isKindOfClass:[NSArray class]])
            {
                [subArrayArray addObject:key];
            }
        }
    }];
    if (keyToDeleteArray.count > 0)
    {
        for (id key in keyToDeleteArray)
        {
            [mutableDict removeObjectForKey:key];
        }
    }
    if (subDictKeyArray.count > 0)
    {
        for (id key in subDictKeyArray)
        {
            mutableDict[key] = [self handleDictionary:mutableDict[key]];
        }
    }
    if (subArrayArray.count > 0)
    {
        for (id key in subArrayArray)
        {
            mutableDict[key] = [self handleArray:mutableDict[key]];
        }
    }
    
    return [mutableDict copy];
}

/**
 *
 *  处理数组里的字典元素, 去掉所有字典里 key = <null> 的键值对
 *
 *  @param array 数组
 *
 *  @return 处理后的字典
 */
- (NSArray *)handleArray:(NSArray *)array
{
    NSMutableArray *mutableArray = [NSMutableArray arrayWithArray:array];
    
    NSMutableArray *subDictKeyArray = [NSMutableArray array];
    NSMutableArray *subArrayArray = [NSMutableArray array];
    [mutableArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[NSDictionary class]])
        {
            [subDictKeyArray addObject:@(idx)];
        }
        else if ([obj isKindOfClass:[NSArray class]])
        {
            [subArrayArray addObject:@(idx)];
        }
    }];
    if (subDictKeyArray.count > 0)
    {
        for (NSNumber *idxNumber in subDictKeyArray)
        {
            NSUInteger index = [idxNumber unsignedIntegerValue];
            NSDictionary *dict = mutableArray[index];
            mutableArray[index] = [self handleDictionary:dict];
        }
    }
    if (subArrayArray.count > 0)
    {
        for (NSNumber *idxNumber in subArrayArray)
        {
            NSUInteger index = [idxNumber unsignedIntegerValue];
            NSArray *subArr = mutableArray[index];
            mutableArray[index] = [self handleArray:subArr];
        }
    }
    return [mutableArray copy];
}

/**
 *
 *  处理网络返回值, 去掉所有字典里 key = <null> 的键值对
 *
 *  @param responseObject 网络返回
 *
 *  @return 处理后的返回
 */
- (id)handledResponseObject:(id)responseObject
{
    if ([responseObject isKindOfClass:[NSDictionary class]])
    {
        return [self handleDictionary:(NSDictionary *)responseObject];
    }
    else if ([responseObject isKindOfClass:[NSArray class]])
    {
        return [self handleArray:(NSArray *)responseObject];
    }
    return responseObject;
}

@end
