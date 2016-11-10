//
//  SJQBaseAPIManager.h
//  SheJiQuan
//
//  Created by yshbyy on 15/11/12.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//


/*!
 @header SJQBaseAPIManager.h
 @abstract API接口，本文件定义了所有API接口的基类，协议方法及相关常量。
 @author yshbyy
 */


#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "APIManagerResponseDataReformer.h"

#define kSJQ_HTTP_REQUEST_OUT_TIME 15  //请求超时时间
#define kRequestPublicKey @"3C58527D28"


@class SJQBaseAPIManager;

//app用到的HTTP请求方法
FOUNDATION_EXTERN NSString *const kAPIManagerRequestMethodGET;
FOUNDATION_EXTERN NSString *const kAPIManagerRequestMethodPOST;
//错误Domain
FOUNDATION_EXTERN NSString *const kAPIManagerErrorDomain;

/**
 API请求错误类型

 - APIManagerErrorTypeNone:        没有错误，请求成功
 - APIManagerErrorTypeSuccessZero: success=0
 - APIManagerErrorTypeCancel:      用户取消
 - APIManagerErrorTypeNULL:        data为null
 - APIManagerErrorTypeOutTime:     连接超时
 - APIManagerErrorTypeNotNetwork:  无网络
 */
typedef NS_ENUM(NSUInteger, APIManagerErrorType) {
    APIManagerErrorTypeNone,
    APIManagerErrorTypeSuccessZero,
    APIManagerErrorTypeCancel,
    APIManagerErrorTypeNULL,
    APIManagerErrorTypeOutTime,
    APIManagerErrorTypeNotNetwork
};

/**
 API请求着陆点，实现该协议以获取API请求的相关信息，包括状态，返回数据等
 */
@protocol APIManagerDelegate <NSObject>
@optional

/*!
 @brief 请求成功后的回调
 @param apiManager api请求对象
 */
- (void)apiManagerDidSuccess:(SJQBaseAPIManager *)apiManager;

/*!
 @brief 请求失败的回调
 @param apiManager api请求对象
 */
- (void)apiManagerDidFailure:(SJQBaseAPIManager *)apiManager;

/**
 手动取消请求回调，调用 cancelLoadding 或 cancelAllLoadding 后立即生效。

 @param apiManager apiManager description
 */
- (void)apiManagerWillCancel:(SJQBaseAPIManager *)apiManager;

/**
 内部 AFNetworking 在异步取消请求成功后回调

 @param apiManager api请求对象
 */
- (void)apiManagerDidCancel:(SJQBaseAPIManager *)apiManager;
@end

/**
 SJQBaseAPIManager 的子类必须遵循此协议，实现请求所必须的参数。此功能实现可替换为父类方法子类必须重写，但那样的话，子类漏写某个方法编译器不会给出警告，容易出错。利用porotocal就能很清晰的写明那些方法必须在子类里边实现。
 */
@protocol APIManager <NSObject>

@required

/*!
 @brief 请求方法
 @return GET or POST
 */
- (NSString *)apiManagerRequestMethod;

/*!
 @brief 请求路径
 @return 路径
 */
- (NSString *)apiManagerRequestPath;

@optional

/*!
 @brief header中配置的接口版本号
 @return 接口版本
 */
- (NSString *)apiManagerInterfaceVersion;

/*!
 @brief 请求域名
 @return 域名
 */
- (NSString *)apiManagerRequestHost;

/*!
 @brief 请求参数
 @return 参数
 */
- (id)apiManagerRequestParametters;

/*!
 @brief 请求头处理，URLProtocol处理
 @param request 请求对象
 @return 配置好的请求
 */
- (NSMutableURLRequest *)apiManagerConfigRequest:(NSURLRequest *)request;

/****************************************************************************************************************************************
 ***************************子类可在回调成功失败之前做一些统一的处理，例如分页请求时，请求失败pageIndex可在此方法中***********************************
 ****************************************************************************************************************************************/
/*!
 @brief 请求失败的回调
 */
- (void)apiManagerDidFailure;

@end


/**
 参数拦截器，指定代理即可对参数进行二次处理
 接口参数首先由 SJQBaseAPIManager 的 childManager 对象返回，然后会由 parameterIntercetor 进行二次处理
 */
@protocol APIManagerParameterInterceptor <NSObject>
@required

/*!
 @brief 对接口的参数进行二次处理
 @param apiManager api请求对象
 @param parameters 原始参数
 @return 处理后的参数
 */
- (id)apiManager:(SJQBaseAPIManager *)apiManager handleParamters:(id)parameters;
@end

/**
 本类处理APP的所有网络请求。
 */
@interface SJQBaseAPIManager : NSObject

+ (void)setBaseDomain:(NSString *)domain;
/**
 请求发生错误时的错误对象
 */
@property (nonatomic, strong) NSError *error;

/**
 错误描述
 */
@property (nonatomic, copy) NSString *errorDescription;

/**
 接口返回的message
 */
@property (nonatomic, copy) NSString *message;
/**
 错误类型
 */
@property (nonatomic, assign) APIManagerErrorType errorType;
/**
 代理请求过程中的成功，失败，取消请求的处理
 */
@property (nonatomic, weak) id<APIManagerDelegate> delegate;//代理，请求处理完毕之后会调用
/**
 请求成功后的数据处理代理对象
 */
@property (nonatomic, strong) id<APIManagerResponseDataReformer> reformer;//请求成功之后数据处理，此处使用强引用，使用时需注意。
/**
 请求前处理请求参数的代理对象
 */
@property (nonatomic, weak) id<APIManagerParameterInterceptor> parameterIntercetor;//参数拦截器

/**
 指向自己，为了让子类有机会实现响应的请求协议
 */
@property (nonatomic, weak) NSObject<APIManager> *childManager;//给自己设置代理
/**
 请求成功返回的数据
 */
@property (nonatomic, strong, readonly) id responseData;//成功后的数据

/**
 是否先加载本地缓存再请求服务器数据。默认为YES。
 设置为NO时，将不回调本地缓存数据，直接请求服务器数据。在列表页加载页码不为1时设置为NO，防止加载本地数据。
 只在GET请求有效。
 */
@property (nonatomic, assign) BOOL loadCacheDataFist;
/**
 是否是缓存数据
 */
@property (nonatomic, assign, readonly) BOOL isCache;

/*!
 *  @brief  创建一个带返回数据处理器的请求，reformer是强引用，不可指定self等可能造成循环引用的对象
 */
- (instancetype)initWithReformer:(id<APIManagerResponseDataReformer>)reformer;

/*!
 *  @brief 方便子类重写请求头时，使用super调用基本头处理
 *  @param request 请求
 *  @return 处理后的请求
 */
- (NSMutableURLRequest *)apiManagerConfigRequest:(NSURLRequest *)request;

/*!
 *  @brief  发送请求
 */
- (void)startLoadding;

/*!
 *  @brief  取消请求
 */
- (void)cancelLoadding;

/*!
 *  @brief 取消实例的operationQueue里的所有请求
 */
- (void)cancelAllLoadding;

/**
 发出请求，上传文件使用，带拼接body的block

 @param blok 拼接body的block

 @return 请求操作
 */
- (AFHTTPRequestOperation *)startLoaddingWithConstructingBodyWithBlock:(void(^)(id <AFMultipartFormData> formData))blok;

/**
 设置请求进度回调（上传）

 @param block 回调
 */
- (void)setUpLoadProgressBlock:(void(^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

/**
 设置请求进度回调（下载）
 
 @param block 回调
 */
- (void)setDownLoadProgressBlock:(void(^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block;

#pragma mark - 请求的一些参数

@property (nonatomic, copy, readonly) NSString *host;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *method;
@property (nonatomic, strong, readonly) id parametters;

@end


