//
//  APIManagerResponseDataReformer.h
//  SheJiQuan
//
//  Created by yshbyy on 16/5/27.
//  Copyright © 2016年 BaoliNetworkTechnology. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 API接口返回数据处理协议
 */
@protocol APIManagerResponseDataReformer <NSObject>

@required

/**
 实现这个方法，并利用原始数据 responseData ，返回一个你想要的数据

 @param responseData 原始数据

 @return 处理后的数据
 */
- (id)apiManagerReformResponseData:(id)responseData;

@end
