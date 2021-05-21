//
//  Zequest+Cache.m
//  Zequest
//
//  Created by lzackx on 2021/5/19.
//

#import "Zequest+Cache.h"
#import <CommonCrypto/CommonDigest.h>
#import "ZequestPrivate.h"

@implementation Zequest (Cache)

// MARK: - Set Cache
- (void)cacheURL:(NSString *)url cachedResponse:(NSString *)cachedResponse {
	if (url == nil || cachedResponse == nil) {
		return;
	}
	NSString *key = [Zequest md5ForString:url];
	[self cacheToMemoryWithKey:key cachedResponse:cachedResponse];
	[self cacheToDiskWithKey:key cachedResponse:cachedResponse];
}

- (void)cacheToMemoryWithKey:(NSString *)key cachedResponse:(NSString *)cachedResponse {
	[self.commonCache setObject:cachedResponse forKey:key];
}

- (void)cacheToDiskWithKey:(NSString *)key cachedResponse:(NSString *)cachedResponse {
	NSString *path = [Zequest pathForCachesDirectory];
	if ([[NSFileManager defaultManager] isWritableFileAtPath:path] == NO) {
		return;
	}
	path = [path stringByAppendingPathComponent:key];
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		@try {
			if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
				[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			}
			[cachedResponse writeToFile:path
							 atomically:YES
							   encoding:NSUTF8StringEncoding
								  error:nil];
		} @catch (NSException *exception) {
#ifdef DEBUG
			NSLog(@"[Zequest]: Cache to disk exception: %@", exception);
#endif
		} @finally {
			
		}
	}];
	[self.cacheQueue addOperation:operation];
}

// MARK: - Get Cache
- (NSString *)getCachedResponseWithURL:(NSString *)url {
	if (url == nil) {
		return nil;
	}
	NSString *cachedResponse = [self getCachedResponseFromMemoryWithURL:url];
	if (cachedResponse != nil) {
		return cachedResponse;
	}
	cachedResponse = [self getCachedResponseFromDiskWithURL:url];
	return cachedResponse;
}

- (NSString *)getCachedResponseFromMemoryWithURL:(NSString *)url {
	NSString *key = [Zequest md5ForString:url];
	NSString *cachedResponse = [self.commonCache objectForKey:key];
	return cachedResponse;
}

- (NSString *)getCachedResponseFromDiskWithURL:(NSString *)url {
	NSString *path = [Zequest md5ForString:url];
	path = [[Zequest pathForCachesDirectory] stringByAppendingPathComponent:path];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
		return nil;
	}
	NSString *cachedResponse = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	return cachedResponse;
}


// MARK: - Private Class Methods
+ (NSString *)md5ForString:(NSString *)string {
   const char *cStr = [string UTF8String];
   unsigned char digest[CC_MD5_DIGEST_LENGTH];
   CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );
   NSMutableString *md5String = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
   for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
	   [md5String appendFormat:@"%02x", digest[i]];

   return md5String;
}

+ (NSString *)pathForCachesDirectory {
	NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
	path = [path stringByAppendingPathComponent:ZEQUEST_CACHE_DIRECTORY_NAME];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
		[[NSFileManager defaultManager] createDirectoryAtPath:path
								  withIntermediateDirectories:YES
												   attributes:nil
														error:nil];
	}
	return path;
}

@end
