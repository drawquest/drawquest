//
//  STPersistentCache.h
//
//  Created by Buzz Andersen on 6/24/11.
//  Copyright 2011 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STDataStoreController.h"


@class STPersistentCacheItem;


extern NSString *STPersistentCacheItemUpdatedNotification;
extern NSString *STPersistentCacheItemUserInfoItemKey;
extern NSString *STPersistentCacheItemUserInfoDataKey;


typedef void (^STPersistentCacheBlock)(void);


@interface STPersistentCache : STDataStoreController <NSCacheDelegate> {
    NSCache *memoryCache;
    
    NSString *cacheName;
    NSString *fileCachePath;
    unsigned long long maximumFileCacheSize;
    
    BOOL needsCacheTruncation;
}

@property (nonatomic, strong, readonly) NSString *fileCachePath;
@property (nonatomic, assign) NSInteger maximumMemoryCacheSize;
@property (nonatomic, assign) unsigned long long maximumFileCacheSize;
@property (nonatomic, assign, readonly) unsigned long long totalFileCacheSize;

// Static Methods
+ (NSString *)metadataModelPath;

// Initialization

// designated initializer
- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootPath;

- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootDirectory modelPath:(NSString *)inModelPath MSDesignatedInitializer(initWithIdentifier:rootDirectory:);

// Public Methods
- (void)setCacheData:(NSData *)inData forKey:(NSString *)inKey;
- (void)setCacheData:(NSData *)inData forKey:(NSString *)inKey inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
- (void)setCacheData:(NSData *)inData forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;

- (void)setFileCacheData:(NSData *)inData forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;

- (void)addCacheDataFromFileAtPath:(NSString *)inPath forKey:(NSString *)inKey;
- (void)addCacheDataFromFileAtPath:(NSString *)inPath forKey:(NSString *)inKey inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
- (void)addCacheDataFromFileAtPath:(NSString *)inPath forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes inBackground:(BOOL)inBackground  didPersistBlock:(STPersistentCacheBlock)didPersistBlock;

- (BOOL)hasCacheDataForKey:(NSString *)inKey;
- (NSData *)cacheDataForKey:(NSString *)inKey;
- (NSData *)fileCacheDataForKey:(NSString *)inKey;
- (NSDictionary *)attributesForKey:(NSString *)inKey;

- (void)removeCacheDataForKey:(NSString *)inKey;
- (void)clearCache;

@end