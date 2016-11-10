//
//  SJQBaseAPIManager.m
//  SheJiQuan
//
//  Created by yshbyy on 15/11/12.
//  Copyright © 2015年 haiyabtx. All rights reserved.
//

#import "SJQBaseAPIManager.h"
//#import "NSString+MD5.h"
#import "SJQCacheObject.h"
#import "SJQRequestCache.h"
//#import "AppDelegate.h"

#import "APIBaseReformer.h"
#import "SJQNetworkReachability.h"

//#import "HTTPError.h"
//#import "UIDevice+model.h"

static NSString *_APIManagerBaseDomain = nil;

static NSString *kAPIManagerErrorCancelString = @"取消操作";

NSString *const kAPIManagerRequestMethodGET = @"GET";
NSString *const kAPIManagerRequestMethodPOST = @"POST";
//错误Domain
NSString *const kAPIManagerErrorDomain = @"kAPIManagerErrorDomain";


#if !DEBUG

#define APILog(...)

#else

#define APILog(format, ...) printf("class: <%p %s:(%d) > method: %s \n%s\n", self, [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __PRETTY_FUNCTION__, [[NSString stringWithFormat:(format), ##__VA_ARGS__] UTF8String] )
//        #define SJQLog(...) NSLog(@"%s %d \n %@ \n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#endif


@interface SJQBaseAPIManager ()

//AFNetworking
@property (nonatomic, strong) NSMutableArray *operations;
@property (nonatomic, strong) AFHTTPRequestOperation *operation;
@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;
//服务器返回数据
@property (nonatomic, strong, readwrite) id responseData;
//缓存
@property (nonatomic, strong) SJQRequestCache *requestCache;
@property (nonatomic, strong) SJQCacheObject *cacheObject;
@property (nonatomic, assign, readwrite) BOOL isCache;

//请求相关配置
@property (nonatomic, copy, readwrite) NSString *host;
@property (nonatomic, copy, readwrite) NSString *path;
@property (nonatomic, copy, readwrite) NSString *method;
@property (nonatomic, strong, readwrite) id parametters;

@end

@implementation SJQBaseAPIManager

+ (void)setBaseDomain:(NSString *)domain {
    _APIManagerBaseDomain = domain;
}

- (AFHTTPRequestOperationManager *)manager {
    if (!_manager) {
        _manager = [AFHTTPRequestOperationManager manager];
        [_manager.operationQueue setMaxConcurrentOperationCount:3];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    return _manager;
}
- (instancetype)init {
    return [self initWithReformer:nil];
}
- (instancetype)initWithReformer:(id<APIManagerResponseDataReformer>)reformer {
    if (self = [super init]) {
        _delegate = nil;
        _reformer = reformer ? reformer : [[APIBaseReformer alloc] init];
        _errorType = APIManagerErrorTypeNone;
        _requestCache = [SJQRequestCache shareCache];
        _loadCacheDataFist = NO;
        
        if ([self conformsToProtocol:@protocol(APIManager)]) {
            self.childManager = (NSObject<APIManager> *)self;
        }
    }
    return self;
}

#pragma mark - apiManager

- (NSString *)apiManagerRequestHost {
    return _APIManagerBaseDomain;
}
- (NSMutableURLRequest *)apiManagerConfigRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    //设置header
//    if (kUserIsLogin) {
//        [mutableRequest setValue:kCurrentLoginUser.loginInfo.token forHTTPHeaderField:@"Token"];//用户token
//    }
    if ([self.childManager respondsToSelector:@selector(apiManagerInterfaceVersion)]) {
        [mutableRequest setValue:[self.childManager apiManagerInterfaceVersion] forHTTPHeaderField:@"AppAgent"];
    } else {
//        [mutableRequest setValue:kAPIInterfaceVersion(@"2.0") forHTTPHeaderField:@"AppAgent"];//固定
    }
    [mutableRequest setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forHTTPHeaderField:@"Version"];//当前APP版本号
    [mutableRequest setTimeoutInterval:kSJQ_HTTP_REQUEST_OUT_TIME];
    
    NSString *oringe_MD5 = nil;
    if (mutableRequest.URL.query) {
        oringe_MD5 = [NSString stringWithFormat:@"%@?%@%@",mutableRequest.URL.path,mutableRequest.URL.query,kRequestPublicKey];
    } else {
        oringe_MD5 = [NSString stringWithFormat:@"%@%@",mutableRequest.URL.path,kRequestPublicKey];
    }
//    oringe_MD5 = [oringe_MD5 MD5String];
    [mutableRequest setValue:oringe_MD5 forHTTPHeaderField:@"Hash"];
    return mutableRequest;
}

#pragma mark - 自带方法

- (void)configRequestBaseURL {
    //请求方法
    if (self.childManager) {
        self.method = [self.childManager apiManagerRequestMethod];
    } else {
        self.method = @"GET";
    }
//    self.method = [self.childManager apiManagerRequestMethod];
    //请求地址
    if ([self.childManager respondsToSelector:@selector(apiManagerRequestHost)]) {
        self.host = [self.childManager apiManagerRequestHost];
    } else {
        self.host = [self apiManagerRequestHost];
    }
    //请求路径
    self.path = [self.childManager apiManagerRequestPath];
    //请求参数
    self.parametters = [self getParameters];
}
- (AFHTTPRequestOperation *)startLoaddingWithConstructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block {
    //判断网络环境
    if (!kSJQNetworkReachable) {
        self.errorDescription = @"请检查您的网络环境";
        [self request:nil failure:[NSError errorWithDomain:kAPIManagerErrorDomain code:APIManagerErrorTypeNotNetwork userInfo:@{NSLocalizedDescriptionKey:@"请检查您的网络环境"}]];
        return nil;
    }
    
    NSError *serializationError = nil;
    
    //生成请求地址，参数，请求方法等
    [self configRequestBaseURL];
    //创建请求对象
    NSMutableURLRequest *request = [self.manager.requestSerializer multipartFormRequestWithMethod:_method URLString:[NSString stringWithFormat:@"%@%@",_host,_path] parameters:_parametters constructingBodyWithBlock:block error:&serializationError];
    
    if (serializationError) {
        [self request:request failure:serializationError];
        return nil;
    }
    self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    //配置请求头
    if ([self.childManager respondsToSelector:@selector(apiManagerConfigRequest:)]) {
        request = [self.childManager apiManagerConfigRequest:request];
    } else {
        request = [self apiManagerConfigRequest:request];
    }
    
    //网络请求数据
    return [self loadOnlineWithRequest:request];
}
- (void)startLoadding {
    //判断网络环境
    if (!kSJQNetworkReachable) {
        self.errorDescription = @"请检查您的网络环境";
        [self request:nil failure:[NSError errorWithDomain:kAPIManagerErrorDomain code:APIManagerErrorTypeNotNetwork userInfo:@{NSLocalizedDescriptionKey:@"请检查您的网络环境"}]];
        return;
    }
    
    NSError *serializationError = nil;
    //生成请求地址，参数，请求方法等
    [self configRequestBaseURL];
    
    //创建请求对象
    NSMutableURLRequest *request = [self.manager.requestSerializer requestWithMethod:_method URLString:[NSString stringWithFormat:@"%@%@",_host,_path] parameters:_parametters error:&serializationError];
    
    if (serializationError) {
        [self request:request failure:serializationError];
        return;
    }
    //配置请求头
    if ([self.childManager respondsToSelector:@selector(apiManagerConfigRequest:)]) {
        request = [self.childManager apiManagerConfigRequest:request];
    } else {
        request = [self apiManagerConfigRequest:request];
    }
    
    //针对GET请求，根据ETag判断该地址资源是否发生改变
//    if ([_method isEqualToString:kAPIManagerRequestMethodGET]) {
//        __weak typeof(self) weakSelf = self;
//        [self.requestCache cacheWithRequest:request complitionHandle:^(SJQCacheObject *cacheObject) {
//            
//            if (cacheObject) {
//                //缓存对象（包含NSHTTPURLResponse，allHeaders中的ETag、data）
//                weakSelf.cacheObject = [cacheObject copy];
//                NSError *responseSerializerError = nil;
//                
//                //判断是否优先使用本地缓存数据
//                if (_loadCacheDataFist) {
//                    //先回调一次本地缓存数据
//                    id responseData = [weakSelf.manager.responseSerializer responseObjectForResponse:weakSelf.cacheObject.response data:weakSelf.cacheObject.responseData error:nil];
//                    if (responseData) {
//                        [self request:nil success:responseData];
//                    }
//                }
//                
//                //如果本地有缓存，判断ETag值是否发生变化
//                if (responseSerializerError == nil)
//                {
////                    [request setValue:[cacheObject.response.allHeaderFields valueForKey:@"Etag"] forHTTPHeaderField:@"If-None-Match"];
//                }
//            }
//            //加载服务器数据
//            [weakSelf loadOnlineWithRequest:request];
//        }];
//    } else {
        [self loadOnlineWithRequest:request];
//    }
}
- (void)cancelLoadding {
    if (self.delegate && [self.delegate respondsToSelector:@selector(apiManagerWillCancel:)]) {
        [self.delegate apiManagerWillCancel:self];
    }
    [self.operation cancel];
    self.operation = nil;
}

- (void)cancelAllLoadding {
    self.operation = nil;
    [[AFHTTPRequestOperationManager manager].operationQueue cancelAllOperations];
}

#pragma mark - 私有方法
//获取请求参数
- (id)getParameters {
    id parametters;
    if (self.childManager && [self.childManager respondsToSelector:@selector(apiManagerRequestParametters)]) {
       parametters = [self.childManager apiManagerRequestParametters];
    }
    if (self.parameterIntercetor && [self.parameterIntercetor respondsToSelector:@selector(apiManager:handleParamters:)]) {
        parametters = [self.parameterIntercetor apiManager:self handleParamters:parametters];
    }

    return parametters;
}
//去服务器请求
- (AFHTTPRequestOperation *)loadOnlineWithRequest:(NSURLRequest *)request {
    __weak typeof(self) weakSelf = self;    
    //创建一个请求操作并执行
     AFHTTPRequestOperation *operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSInteger HTTPStatusCode = operation.response.statusCode;
         if (HTTPStatusCode == 304) {//可以使用缓存
             APILog(@"\n请求地址：%@\nHeader:%@\n参数：%@\n--------------------------HTTP status code 304--------------------------\n--------------------------使用本地缓存--------------------------\napi数据请求成功：\n%@\n\n%@",
                    operation.request.URL.absoluteString,
                    operation.request.allHTTPHeaderFields,
                    _parametters,
                    operation.request.URL.absoluteString,
                    responseObject);
             
             id responseData = [weakSelf.manager.responseSerializer responseObjectForResponse:weakSelf.cacheObject.response data:weakSelf.cacheObject.responseData error:nil];
             [weakSelf request:operation success:responseData];
         } else {
             APILog(@"\n请求地址：%@\nHeader:%@\n参数：%@\n--------------------------HTTP status code %ld--------------------------\n--------------------------使用服务器数据--------------------------\napi数据请求成功：\n%@\n\n%@",
                    operation.request.URL.absoluteString,
                    operation.request.allHTTPHeaderFields,
                    _parametters,
                    (long)operation.response.statusCode,
                    operation.request.URL.absoluteString,
                    responseObject);
             __strong typeof(weakSelf) strongSelf = weakSelf;
             weakSelf.message = [[responseObject valueForKey:@"message"] isKindOfClass:[NSNull class]] ? nil : [responseObject valueForKey:@"message"];
             //执行成功回调
             [strongSelf request:operation success:responseObject];
         }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (operation.response.statusCode == 304) {//可以使用缓存
            NSError *err = nil;
            id responseData = [weakSelf.manager.responseSerializer responseObjectForResponse:weakSelf.cacheObject.response data:weakSelf.cacheObject.responseData error:&err];
            APILog(@"\n请求地址：%@\nHeader:%@\n参数：%@\n--------------------------HTTP status code 304--------------------------\n--------------------------使用本地缓存--------------------------\napi数据请求成功：\n%@\n\n%@",
                   operation.request.URL.absoluteString,
                   operation.request.allHTTPHeaderFields,
                   _parametters,
                   operation.request.URL.absoluteString,
                   responseData);
            if (responseData == nil) {
                [[SJQRequestCache shareCache] removeCacheWithRequest:operation.request];
            }
            [weakSelf request:operation success:responseData];
        } else {
            APILog(@"\napi数据请求失败:\n请求地址：\n%@\nHeader:%@\n参数\n：%@\n错误：\n%@",
                   operation.request.URL.absoluteString,
                   operation.request.allHTTPHeaderFields,
                   _parametters,
                   error);
            __strong typeof(weakSelf) strongSelf = weakSelf;

            if (operation.response.statusCode >= 500) {
                error = [NSError errorWithDomain:@"服务器错误" code:500 userInfo:@{NSLocalizedDescriptionKey:@"服务器在开小差~"}];
            }
            //执行失败回调
            [strongSelf request:request failure:error];
        }
        //记录错误日志
//        [[weakSelf class] saveErrorWithOparation:operation andError:error];
    }];

    self.operation = operation;
    [self.manager.operationQueue addOperation:operation];
    return operation;
}
//请求成功处理,分新接口，旧接口，
- (void)request:(AFHTTPRequestOperation *)operation success:(id)responseData {
    
    if ([responseData valueForKey:@"result"]) {
        [self handleNewRequest:operation success:responseData];
    } else {
        [self handleOldRequest:operation success:responseData];
    }
}
- (void)handleNewRequest:(AFHTTPRequestOperation *)operation success:(id)responseData {
    self.isCache = operation == nil;

    BOOL isRightData = NO;
    NSError *error = nil;
    //验证返回数据准确性
    //首先验证responsedata是否存在，并且success是否成功
    if ([responseData valueForKey:@"success"] && [[responseData valueForKey:@"success"] boolValue]) {
        isRightData = YES;
    } else {
        //设置错误信息
        NSString *errorDescription = @"发生未知错误";
        if (![[responseData valueForKey:@"error"] isKindOfClass:[NSNull class]]) {
            
            id responseError = [responseData valueForKey:@"error"];
            if ([responseError isKindOfClass:[NSDictionary class]]) {
                if (![[responseError valueForKey:@"message"] isEqualToString:@""]) {
                    errorDescription = [responseError valueForKey:@"message"];
                }
            }

            error = [NSError errorWithDomain:kAPIManagerErrorDomain code:APIManagerErrorTypeSuccessZero userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorDescription,NSLocalizedDescriptionKey, nil]];
        }
    }
    
    if (isRightData) {
        if (operation && [_method isEqualToString:kAPIManagerRequestMethodGET]) {
            [self.requestCache saveCacheWithResponse:operation.response responseData:operation.responseData forRequest:operation.request];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(apiManagerDidSuccess:)]) {
            self.responseData = responseData;
            if (self.reformer && [self.reformer respondsToSelector:@selector(apiManagerReformResponseData:)]) {
                self.responseData = [self.reformer apiManagerReformResponseData:responseData];
            }
            [self.delegate apiManagerDidSuccess:self];
        }
    } else {
        //调用错误回调
        [self request:operation.request failure:error];
    }
}
- (void)handleOldRequest:(AFHTTPRequestOperation *)operation success:(id)responseData {
    self.isCache = operation == nil;
    BOOL isRightData = NO;
    NSError *error = nil;
    //验证返回数据准确性
    //首先验证responsedata是否存在，并且success是否成功
    if ([responseData valueForKey:@"success"] && [[responseData valueForKey:@"success"] boolValue]) {
        isRightData = YES;
    } else {
        //设置错误信息
        NSString *errorDescription = @"发生未知错误";
        if (![[responseData valueForKey:@"message"] isKindOfClass:[NSNull class]]) {
            
            if (responseData && ![[responseData valueForKey:@"message"] isEqualToString:@""]) {
                errorDescription = [responseData valueForKey:@"message"];
            }
            error = [NSError errorWithDomain:kAPIManagerErrorDomain code:APIManagerErrorTypeSuccessZero userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorDescription,NSLocalizedDescriptionKey, nil]];
        }
    }
    
    if (isRightData) {
        if (operation && [_method isEqualToString:kAPIManagerRequestMethodGET]) {
            [self.requestCache saveCacheWithResponse:operation.response responseData:operation.responseData forRequest:operation.request];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(apiManagerDidSuccess:)]) {
            self.responseData = responseData;
            if (self.reformer && [self.reformer respondsToSelector:@selector(apiManagerReformResponseData:)]) {
                self.responseData = [self.reformer apiManagerReformResponseData:responseData];
            }
            [self.delegate apiManagerDidSuccess:self];
        }
    } else {
        //调用错误回调
        [self request:operation.request failure:error];
    }
}
//请求失败处理
- (void)request:(NSURLRequest *)request failure:(NSError *)error {
    _error = error;
    if (error.code == NSURLErrorCancelled) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(apiManagerDidCancel:)]) {
            self.errorType = APIManagerErrorTypeCancel;
            self.errorDescription = kAPIManagerErrorCancelString;
            [self.delegate apiManagerDidCancel:self];
        }
    } else {
        self.errorType = error.code;
        self.errorDescription = error.localizedDescription;
        
        if (self.childManager && [self.childManager respondsToSelector:@selector(apiManagerDidFailure)]) {
            [self.childManager apiManagerDidFailure];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(apiManagerDidFailure:)]) {
            [self.delegate apiManagerDidFailure:self];
        }
    }
}

#pragma mark - 请求进度
- (void)setUpLoadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    [self.operation setUploadProgressBlock:block];
}
- (void)setDownLoadProgressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))block {
    [self.operation setDownloadProgressBlock:block];
}


//+ (AFHTTPRequestOperation *)saveErrorWithOparation:(AFHTTPRequestOperation *)operation andError:(NSError *)error {
//    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
//        
//        HTTPError *httpError = [HTTPError MR_createEntityInContext:localContext];
//        httpError.client = @(kSJQ_Client);
//        httpError.creatTime = [NSDate currentTime];
//        httpError.host = operation.request.URL.host;
//        httpError.errorCode = @(error.code);
//        httpError.httpMethod = [operation.request.HTTPMethod stringByAppendingFormat:@"——%@",error.domain];
//        httpError.networkType = @([UIApplication getNetWorkStates]);
//        httpError.pathAndQuery = operation.request.URL.path;
//        httpError.device = [UIDevice currentDevice].realyModel;
//        httpError.userAgent = [operation.request valueForHTTPHeaderField:@"User-Agent"];
//        httpError.macAddress = [[UIDevice currentDevice].identifierForVendor UUIDString];
//    } completion:nil];
//    return nil;
//}
- (void)dealloc {
    self.manager = nil;
    self.operation = nil;
}
@end
