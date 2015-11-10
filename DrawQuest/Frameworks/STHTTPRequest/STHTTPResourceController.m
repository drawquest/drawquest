//
//  STHTTPResourceController.m
//
//  Created by Buzz Andersen on 9/17/12.
//  Copyright (c) System of Touch. All rights reserved.
//

#import "STHTTPResourceController.h"
#import "DQHTTPRequestQueue.h"
#import "DQHTTPRequest.h"
#import "STPersistentCache.h"
#import <ImageIO/ImageIO.h>

// TO DO: If we have the default version of a cached item,
// we should be able to return that if a request variation
// isn't already cached

NSString *STHTTPResourceControllerDataLoadNotification = @"STHTTPResourceControllerLoadedDataNotification";
NSString *STHTTPResourceControllerImageLoadNotification = @"STHTTPResourceControllerLoadedImageNotification";
NSString *STHTTPResourceControllerNotificationKeyLoadStatus = @"LoadStatus";
NSString *STHTTPResourceControllerNotificationKeyImage = @"Image";
NSString *STHTTPResourceControllerNotificationKeyData = @"Data";
NSString *STHTTPResourceControllerNotificationKeyURL = @"URL";
NSString *STHTTPResourceControllerNotificationKeyCacheKey = @"CacheKey";

@interface STHTTPResourceController ()

@property (nonatomic, strong) DQHTTPRequestQueue *requestQueue;
@property (nonatomic, strong) dispatch_queue_t imageProcessingQueue;
@property (nonatomic, strong) STPersistentCache *resourceCache;
@property (nonatomic, strong) NSCache *imageCache;

- (void)uncompressAndCacheImageData:(NSData *)inData forURL:(NSString *)inURL withCompletionBlock:(STHTTPResourceControllerImageLoadBlock)inCompletionBlock;
- (void)sendImageLoadedNotificationForImage:(UIImage *)inImage URL:(NSString *)inURL loadStatus:(STHTTPResourceControllerLoadStatus)inLoadStatus;
- (void)_sendImageLoadedNotificationForImage:(UIImage *)inImage URL:(NSString *)inURL loadStatus:(STHTTPResourceControllerLoadStatus)inLoadStatus;

@end


@implementation STHTTPResourceController

@synthesize requestQueue;
@synthesize resourceCache;
@synthesize imageCache;

#pragma mark Initialization

- (id)initWithIdentifier:(NSString *)inIdentifier cacheDirectory:(NSString *)inCacheDirectory;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.resourceCache = [[STPersistentCache alloc] initWithIdentifier:inIdentifier rootDirectory:inCacheDirectory];
    self.requestQueue = [[DQHTTPRequestQueue alloc] initWithQueueName:inIdentifier];
    // TODO: increase the max concurrent operation count?
    [self.requestQueue setMaxConcurrentOperationCount:3 completionBlock:nil];
    self.imageCache = [[NSCache alloc] init];
    self.imageCache.totalCostLimit = 20971520; //20 MB
    self.resourceCache.maximumFileCacheSize = 104857600; //200MB
    self.imageCache.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    if (_imageProcessingQueue) {
        dispatch_sync(_imageProcessingQueue, ^{ });
    }

}

- (void)clearResourceCache
{
    [self.resourceCache clearCache];
}

#pragma mark Accessors

- (dispatch_queue_t)imageProcessingQueue;
{
    if (!_imageProcessingQueue) {
        NSString *queueName = [NSString stringWithFormat:@"com.systemoftouch.%@.ImageProcessingQueue", NSStringFromClass([self class])];
        _imageProcessingQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    
    return _imageProcessingQueue;
}

#pragma mark Data Loading

// removed this code because it's not used

#pragma mark Image Loading

- (void)requestImageForURL:(NSString *)inURL forceReload:(BOOL)inForceReload;
{
    [self requestImageForURL:inURL forceReload:inForceReload completionBlock:NULL];
}

- (void)requestImageForURL:(NSString *)inURL forceReload:(BOOL)inForceReload completionBlock:(STHTTPResourceControllerImageLoadBlock)inCompletionBlock;
{
    if (!inURL) {
        if (inCompletionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                inCompletionBlock(nil, STHTTPResourceControllerLoadStatusLoadFailed, nil);
            });
        }
        
        return;
    }
        
    // If we're not forcing a reload, check the cache
    if (!inForceReload) {
        // If we have a memory cached image send that off
        UIImage *image = [self.imageCache objectForKey:inURL];
        if (image) {
            [self sendImageLoadedNotificationForImage:image URL:inURL loadStatus:STHTTPResourceControllerLoadStatusLoadedFromMemoryCache];
            
            if (inCompletionBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    inCompletionBlock(image, STHTTPResourceControllerLoadStatusLoadedFromMemoryCache, nil);
                });
            }
            
            return;
        }
        
        // If we have a disk cached image, uncompress, cache,
        // and send that off
        NSData *cachedData = [self.resourceCache fileCacheDataForKey:inURL];
        if (cachedData) {
            [self uncompressAndCacheImageData:cachedData forURL:inURL withCompletionBlock:inCompletionBlock];
            return;
        }
    }
    
    // If we don't have the image data in the cache or
    // are forcing a reload, do a network request
    DQHTTPRequest *imageRequest = [self.requestQueue requestWithURL:inURL];
    imageRequest.requestMethod = DQHTTPRequestMethodGET;
    
    imageRequest.timeoutInterval = 40.0;
    
    // If the request is successful, cache the data
    // and call the provided completion block
    // if appropriate
    __block typeof(self) blockSelf = self;
    imageRequest.requestDidFinishBlock = ^(DQHTTPRequest *inRequest) {
        NSData *imageData = inRequest.responseData;
        if (imageData)
        {
            [blockSelf uncompressAndCacheImageData:imageData forURL:inURL withCompletionBlock:inCompletionBlock];
            [blockSelf.resourceCache setFileCacheData:imageData forKey:inURL withAttributes:nil inBackground:YES didPersistBlock:NULL];
        }
    };

    // If the request failed, call the failure block
    // if appropriate
    imageRequest.requestDidFailBlock = ^(DQHTTPRequest *inRequest) {
        if (![inRequest isCancelled])
        {
            NSLog(@"Image load failed for URL: %@", inRequest.URL);
        }

        [blockSelf sendImageLoadedNotificationForImage:nil URL:inURL loadStatus:STHTTPResourceControllerLoadStatusLoadFailed];
        
        if (inCompletionBlock)
        {
            inCompletionBlock(nil, STHTTPResourceControllerLoadStatusLoadFailed, inRequest.error);
        }
    };

    [self.requestQueue enqueueRequest:imageRequest resultBlock:nil];
}

#pragma mark Cancellation

- (void)cancelLoadForURL:(NSString *)inURL;
{
    [self.requestQueue cancelRequestsForURL:inURL completionBlock:nil];
}

#pragma mark Private Methods

- (void)uncompressAndCacheImageData:(NSData *)inData forURL:(NSString *)inURL withCompletionBlock:(STHTTPResourceControllerImageLoadBlock)inCompletionBlock;
{
    dispatch_async(self.imageProcessingQueue, ^{
        UIImage *image = nil;
        NSDictionary *options = [NSDictionary dictionaryWithObject:@(YES) forKey:(id)kCGImageSourceShouldCache];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)inData, (__bridge CFDictionaryRef)options);
        if (source)
        {
            CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)options);
            if (cgImage)
            {
                image = [UIImage imageWithCGImage:cgImage];
                if (image)
                {
                    NSUInteger cost = CGImageGetHeight(cgImage) * CGImageGetBytesPerRow(cgImage);
                    [self.imageCache setObject:image forKey:inURL cost:cost];
                }
                CGImageRelease(cgImage);
            }
            CFRelease(source);
        }

        if (image)
        {
            [self sendImageLoadedNotificationForImage:image URL:inURL loadStatus:image ? STHTTPResourceControllerLoadStatusLoadedFromNetwork : STHTTPResourceControllerLoadStatusLoadFailed];
        }

        if (inCompletionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                inCompletionBlock(image, image ? STHTTPResourceControllerLoadStatusLoadedFromNetwork : STHTTPResourceControllerLoadStatusLoadFailed, nil);
            });
        }
    });
}

- (void)sendImageLoadedNotificationForImage:(UIImage *)inImage URL:(NSString *)inURL loadStatus:(STHTTPResourceControllerLoadStatus)inLoadStatus;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _sendImageLoadedNotificationForImage:inImage URL:inURL loadStatus:inLoadStatus];
    });
}

- (void)_sendImageLoadedNotificationForImage:(UIImage *)inImage URL:(NSString *)inURL loadStatus:(STHTTPResourceControllerLoadStatus)inLoadStatus;
{
    if (!inURL) {
        return;
    }
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    NSNumber *loadStatusNumber = @((NSInteger)inLoadStatus);

    [userInfo setObject:inURL forKey:STHTTPResourceControllerNotificationKeyURL];
    [userInfo setObject:loadStatusNumber forKey:STHTTPResourceControllerNotificationKeyLoadStatus];
    
    if (inImage)
    {
        [userInfo setObject:inImage forKey:STHTTPResourceControllerNotificationKeyImage];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:STHTTPResourceControllerImageLoadNotification object:inURL userInfo:userInfo];

}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj;
{
    //NSLog(@"Image cache evicting object: %@", obj);
}

- (void)didReceiveMemoryWarning
{
    //clear the image cache on memory warning
    [self.imageCache removeAllObjects];
}

@end
