//
//  STHTTPResourceController.h
//
//  Created by Buzz Andersen on 9/17/12.
//  Copyright (c) 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPersistentCache;
@class DQHTTPRequestQueue;

typedef enum {
    STHTTPResourceControllerLoadStatusLoadFailed,
    STHTTPResourceControllerLoadStatusLoadedFromNetwork,
    STHTTPResourceControllerLoadStatusLoadedFromDiskCache,
    STHTTPResourceControllerLoadStatusLoadedFromMemoryCache
} STHTTPResourceControllerLoadStatus;

extern NSString *STHTTPResourceControllerDataLoadNotification;
extern NSString *STHTTPResourceControllerImageLoadNotification;
extern NSString *STHTTPResourceControllerNotificationKeyLoadStatus;
extern NSString *STHTTPResourceControllerNotificationKeyImage;
extern NSString *STHTTPResourceControllerNotificationKeyData;
extern NSString *STHTTPResourceControllerNotificationKeyURL;
extern NSString *STHTTPResourceControllerNotificationKeyCacheKey;

typedef NSData *(^STHTTPResourceControllerCompletionBlock)(NSData *, STHTTPResourceControllerLoadStatus, NSError *);
typedef void (^STHTTPResourceControllerImageLoadBlock)(UIImage *, STHTTPResourceControllerLoadStatus, NSError *);



@interface STHTTPResourceController : NSObject <NSCacheDelegate>

@property (nonatomic, strong, readonly) DQHTTPRequestQueue *requestQueue;
@property (nonatomic, strong, readonly) NSCache *imageCache;

// Initialization

// designated initializer
- (id)initWithIdentifier:(NSString *)inIdentifier cacheDirectory:(NSString *)inCacheDirectory;

- (id)init MSDesignatedInitializer(initWithIdentifier:cacheDirectory:);

// Image Loading
- (void)requestImageForURL:(NSString *)inURL forceReload:(BOOL)inForceReload;
- (void)requestImageForURL:(NSString *)inURL forceReload:(BOOL)inForceReload completionBlock:(STHTTPResourceControllerImageLoadBlock)inCompletionBlock;

// Cancellation
- (void)cancelLoadForURL:(NSString *)inURL;

- (void)clearResourceCache;

@end
