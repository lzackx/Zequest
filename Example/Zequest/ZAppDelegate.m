//
//  ZAppDelegate.m
//  Zequest
//
//  Created by lzackx on 05/18/2021.
//  Copyright (c) 2021 lzackx. All rights reserved.
//

#import "ZAppDelegate.h"
#import <Zequest/Zequest.h>

@implementation ZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
		
	[[Zequest shared] registerCommonHeaderParameters:@{
		@"User-Agent": @"zequest",
	}];
	[[Zequest shared] registerCommonBodyParameters:@{
		@"common_body": @"zequest",
	}];
	[[Zequest shared] registerCommonRequestTimeoutInterval:8];
	[[Zequest shared] registerCommonRequestMaxConcurrentOperationCount:4];
	[[Zequest shared] registerCommonRequestTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
		NSLog(@"%@", task);
	}];
	[[Zequest shared] launchReachabilityManagerWithDomain:@"lzackx.com" statusChangeCallback:^(NSInteger status) {
		NSLog(@"Reachability Status: %ld", status);
	}];
	[[Zequest shared] launchCommonHTTPSessionManager];
	[[Zequest shared] get:@"https://raw.githubusercontent.com/lzackx/Zequest/master/Example/zequest.json"
				   header:@{
					   @"header": @"zequest"
				   }
			   parameters:@{
				   @"parameters": @"zequest"
			   }
			  shouldCache:YES
				dataClass:nil
				 progress:^(NSProgress * progress) {
		NSLog(@"progress: %@", progress.userInfo);
	} success:^(NSURLSessionDataTask * task, id object) {
		NSLog(@"%@: %@", task, object);
	} failure:^(NSURLSessionDataTask * task, NSError * error) {
		NSLog(@"%@: %@", task, error);
	}];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
