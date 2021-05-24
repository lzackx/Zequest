//
//  Zequest.m
//  Zequest
//
//  Created by lzackx on 2021/5/19.
//

#import "Zequest.h"
#import "ZequestPrivate.h"
#import "Zequest+Cache.h"
#import <YYKit/NSObject+YYModel.h>

@implementation Zequest

// MARK: - Life Cycle
static Zequest *_shared = nil;

+ (instancetype)shared {
	if (_shared == nil) {
		_shared = [[Zequest alloc] init];
	}
	return _shared;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
	if (_shared == nil) {
		_shared = [[super allocWithZone:zone] init];
	}
	return _shared;
}

- (id)copyWithZone:(nullable NSZone *)zone {
	return self;
}


- (id)mutableCopyWithZone:(nullable NSZone *)zone {
	return self;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		_commonHeaderParameters = [NSDictionary dictionary];
		_commonBodyParameters = [NSDictionary dictionary];
		_commonRequestTimeoutInterval = 8.0;
		_commonAcceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
		_commonRequestTaskDidComplete = nil;
		_commonCache = [[NSCache alloc] init];
		_commonCache.name = ZEQUEST_CACHE_NAME;
		_commonCache.delegate = self;
		_cacheQueue = [[NSOperationQueue alloc] init];
		_cacheQueue.maxConcurrentOperationCount = 1;
		_cacheQueue.name = ZEQUEST_CACHE_NAME;
	}
	return self;
}

// MARK: - Parameters
- (AFHTTPRequestSerializer *)defaultCommonRequestSerializer {
	AFHTTPRequestSerializer *serializer = [AFJSONRequestSerializer serializer];
	serializer.timeoutInterval = self.commonRequestTimeoutInterval;
	return serializer;
}

- (AFHTTPResponseSerializer *)defaultCommonResponseSerializer {
	AFHTTPResponseSerializer *serializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingFragmentsAllowed];
	serializer.acceptableStatusCodes = self.commonAcceptableStatusCodes;
	serializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", nil];
	return serializer;
}

- (void)registerCommonRequestMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
	if (maxConcurrentOperationCount <= 0) {
		return;
	}
	self.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

- (void)registerCommonHeaderParameters:(NSDictionary *)commonHeaderParameters {
	if (commonHeaderParameters == nil) {
		return;
	}
	self.commonHeaderParameters = commonHeaderParameters;
}

- (void)registerCommonBodyParameters:(NSDictionary *)commonBodyParameters {
	if (commonBodyParameters == nil) {
		return;
	}
	self.commonBodyParameters = commonBodyParameters;
}

- (void)registerCommonRequestTimeoutInterval:(NSTimeInterval)requestTimeoutInterval {
	if (requestTimeoutInterval <= 0) {
		return;
	}
	self.commonRequestTimeoutInterval = requestTimeoutInterval;
}

- (void)registerCommonResponseAcceptableStatusCodes:(NSIndexSet *)acceptableStatusCodes {
	if (acceptableStatusCodes == nil) {
		return;
	}
	self.commonAcceptableStatusCodes = acceptableStatusCodes;
}

- (void)registerCommonRequestTaskDidFinishCollectingMetricsBlock:(void(^)(NSURLSession *session, NSURLSessionTask *task, NSURLSessionTaskMetrics * metrics))requestTaskDidFinishCollectingMetricsBlock {
	if (requestTaskDidFinishCollectingMetricsBlock == nil) {
		return;
	}
	self.commonRequestTaskDidFinishCollectingMetrics = requestTaskDidFinishCollectingMetricsBlock;
}

- (void)registerCommonRequestTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))requestTaskDidCompleteBlock {
	if (requestTaskDidCompleteBlock == nil) {
		return;
	}
	self.commonRequestTaskDidComplete = requestTaskDidCompleteBlock;
}

// MARK: - Initialize managers
- (void)launchCommonHTTPSessionManager {
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	configuration.HTTPAdditionalHeaders = self.commonHeaderParameters;
	configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
	configuration.HTTPShouldSetCookies = YES;
	configuration.URLCache = nil;
	self.commonHTTPSessionManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
	self.commonHTTPSessionManager.requestSerializer = [self defaultCommonRequestSerializer];
	self.commonHTTPSessionManager.requestSerializer.timeoutInterval = self.commonRequestTimeoutInterval;
	self.commonHTTPSessionManager.responseSerializer = [self defaultCommonResponseSerializer];
	self.commonHTTPSessionManager.responseSerializer.acceptableStatusCodes = self.commonAcceptableStatusCodes;
	self.commonHTTPSessionManager.operationQueue.maxConcurrentOperationCount = self.maxConcurrentOperationCount;
	[self.commonHTTPSessionManager setTaskDidFinishCollectingMetricsBlock:self.commonRequestTaskDidFinishCollectingMetrics];
	[self.commonHTTPSessionManager setTaskDidCompleteBlock:self.commonRequestTaskDidComplete];
}

// MARK: - Reachability
- (void)launchReachabilityManagerWithDomain:(nullable NSString *)domain
					   statusChangeCallback:(nullable void (^)(NSInteger status))statusChangeCallback {
	if (self.commonReachabilityManager != nil) {
		[self.commonReachabilityManager stopMonitoring];
		[self.commonReachabilityManager setReachabilityStatusChangeBlock:nil];
	}
	if (domain.length > 0) {
		self.commonReachabilityManager = [AFNetworkReachabilityManager managerForDomain:domain];
	} else {
		self.commonReachabilityManager = [AFNetworkReachabilityManager sharedManager];
	}
	[self.commonReachabilityManager startMonitoring];
	[self.commonReachabilityManager setReachabilityStatusChangeBlock:statusChangeCallback];
}

// MARK: - Request API
- (void)get:(NSString *)url
	 header:(NSDictionary *)header
 parameters:(NSDictionary *)parameters
shouldCache:(BOOL)shouldCache
  dataClass:(nullable Class)dataClass
   progress:(nullable void (^)(NSProgress * _Nonnull))progress
	success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
	failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure  {
	// Header
	NSMutableDictionary *h = [NSMutableDictionary dictionaryWithDictionary:self.commonHeaderParameters];
	[h addEntriesFromDictionary:header];
	// Parameters
	NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:self.commonBodyParameters];
	[p addEntriesFromDictionary:parameters];
	// Success
	__weak typeof(self) wSelf = self;
	void (^successCallback)(NSURLSessionDataTask * _Nonnull, id _Nullable) = ^(NSURLSessionDataTask *task, id jsonObject) {
		if (success == nil) {
			return;
		}
		if (shouldCache) {
			NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil] encoding:NSUTF8StringEncoding];
			[wSelf cacheURL:task.currentRequest.URL.absoluteString cachedResponse:jsonString];
		}
		if (dataClass != nil) {
			id dataModel = [dataClass modelWithDictionary:jsonObject];
			if (dataModel != nil) {
				success(task, dataModel);
				return;
			}
		}
		success(task, jsonObject);
	};
	// Failure
	void (^failureCallback)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull) = ^(NSURLSessionDataTask *task, NSError *error) {
		if (failure) {
			failure(task, error);
		}
	};
	[self.commonHTTPSessionManager GET:url
							parameters:p
							   headers:h
							  progress:progress
							   success:successCallback
							   failure:failureCallback];
}

- (void)post:(NSString *)url
	  header:(NSDictionary *)header
  parameters:(NSDictionary *)parameters
 shouldCache:(BOOL)shouldCache
   dataClass:(nullable Class)dataClass
	progress:(nullable void (^)(NSProgress * _Nonnull))progress
	 success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
	 failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
	// Header
	NSMutableDictionary *h = [NSMutableDictionary dictionaryWithDictionary:self.commonHeaderParameters];
	[h addEntriesFromDictionary:header];
	// Parameters
	NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:self.commonBodyParameters];
	[p addEntriesFromDictionary:parameters];
	// Success
	__weak typeof(self) wSelf = self;
	void (^successCallback)(NSURLSessionDataTask * _Nonnull, id _Nullable) = ^(NSURLSessionDataTask *task, id jsonObject) {
		if (success == nil) {
			return;
		}
		if (shouldCache) {
			NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObject options:0 error:nil] encoding:NSUTF8StringEncoding];
			[wSelf cacheURL:task.currentRequest.URL.absoluteString cachedResponse:jsonString];
		}
		if (dataClass != nil) {
			id dataModel = [dataClass modelWithDictionary:jsonObject];
			if (dataModel != nil) {
				success(task, dataModel);
				return;
			}
		}
		success(task, jsonObject);
	};
	// Failure
	void (^failureCallback)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull) = ^(NSURLSessionDataTask *task, NSError *error) {
		if (failure) {
			failure(task, error);
		}
	};
	[self.commonHTTPSessionManager POST:url
							 parameters:p
								headers:h
							   progress:progress
								success:successCallback
								failure:failureCallback];
}

- (NSString *)cachedResponseFor:(NSString *)url {
	NSString *cachedResponse = [self getCachedResponseWithURL:url];
	return cachedResponse;
}

// MARK: - NSCacheDelegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj {
#ifdef DEBUG
	NSLog(@"[Zequest] cache willEvictObject: %@", obj);
#endif
}

@end
