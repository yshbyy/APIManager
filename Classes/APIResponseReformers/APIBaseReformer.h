//
//  BaseReformer.h
//  SheJiQuan
//
//  Created by yshbyy on 15/11/13.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//


/*!
 @header BaseReformer.h
 @abstract 处理API接口返回的数据，默认只清空null数据。如要其他操作，可在子类中重写<APIManagerReformer>协议中的方法
 @author yshbyy
 */

#import <Foundation/Foundation.h>
#import "SJQBaseAPIManager.h"

/**
 处理API接口返回数据的基类，默认去除返回数据中的空键值对和值为 NSNull 对象的键值对。
 当然，你可以继承这个类，以实现自己的返回数据处理方法。但是，没有必要。
 */
@interface APIBaseReformer : NSObject<APIManagerResponseDataReformer>

/**
 处理网络请求返回的json数据

 @param responseObject 原始数据

 @return 去除空键值对和值为 NSNull 对象的键值对
 */
- (id)handledResponseObject:(id)responseObject;

@end
