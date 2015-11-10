//
//  STPersistentCache.m
//
//  Created by Buzz Andersen on 6/24/11.
//  Copyright 2011 System of Touch. All rights reserved.
//

#import "STPersistentCache.h"
#import "STUtils.h"


// Constants
NSString *STPersistentCacheMetadataModelName = @"STPersistentCache";

NSString *STPersistentCacheFileCacheSubdirectoryName = @"Data";

NSString *STPersistentCacheItemEntityName = @"PersistentCacheItem";
NSString *STPersistentCacheItemCacheKeyModelKey = @"key";
NSString *STPersistentCacheItemAddedTimestampModelKey = @"addedTimestamp";
NSString *STPersistentCacheItemFileSizeModelKey = @"fileSize";
NSString *STPersistentCacheItemDataModelKey = @"data";

NSString *STPersistentCacheItemUpdatedNotification = @"STPersistentCacheItemUpdatedNotification";
NSString *STPersistentCacheItemUserInfoItemKey = @"item";
NSString *STPersistentCacheItemUserInfoDataKey = @"data";

const unsigned long long STPersistentCacheDefaultMaximumFileCacheSize = 20971520;

// 2MB      2097152
// 10 MB    10485760
// 20 MB    20971520;


@interface STPersistentCacheItem : NSManagedObject {
    
}

@property (nonatomic, strong) NSString *key;
@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, strong) NSDate *addedTimestamp;
@property (nonatomic, strong) NSDate *updatedTimestamp;
@property (nonatomic, strong) NSDictionary *attributes;

// Public Methods
- (void)initializeForKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes;
- (void)initializeWithData:(NSData *)inData forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes;
- (void)initializeWithPath:(NSString *)inPath forKey:(NSString *)inKey withAttributes:(NSDictionary *)inAttributes;


@end


@interface STPersistentCache ()

@property (nonatomic, strong) NSCache *memoryCache;
@property (nonatomic, assign) BOOL needsCacheTruncation;
@property (nonatomic, strong) NSString *fileCachePath;

+ (NSString *)defaultRootDirectoryForIdentifier:(NSString *)inIdentifier;

// Cache Items
- (STPersistentCacheItem *)cacheItemForKey:(NSString *)inKey;
- (void)removeCacheItem:(STPersistentCacheItem *)inCacheItem;

// Private Methods
- (void)_updateFileCachePath;
- (NSString *)_fileCachePathForKey:(NSString *)inKey;
- (void)_clearFileCache;
- (void)_clearCacheItemsToFitMaxFileCacheSize;
- (void)_clearCacheItemsOfSize:(unsigned long long)inSize;

// Private Core Data Methods
- (STPersistentCacheItem *)_findOrCreateCacheItemForKey:(NSString *)inKey;
- (NSFetchRequest *)_cacheItemsFetchRequest;

@end


@implementation STPersistentCache

@synthesize fileCachePath;
@synthesize maximumFileCacheSize;
@synthesize memoryCache;
@synthesize needsCacheTruncation;

#pragma mark Class Methods

+ (NSString *)metadataModelPath;
{
    return [[NSBundle mainBundle] pathForResource:STPersistentCacheMetadataModelName ofType:@"momd"];
}

+ (NSString *)defaultRootDirectoryForIdentifier:(NSString *)inIdentifier;
{
    NSMutableArray *pathComponents = [[NSMutableArray alloc] init];
    
    // If we're on a Mac, include the app name in the
    // application support path.
    NSFileManager *fm = [NSFileManager new];
#if !TARGET_OS_IPHONE
    [pathComponents addObject:[fm cachePathIncludingAppName]];
#else
    [pathComponents addObject:[fm cachePath]];
#endif
    
    [pathComponents addObject:inIdentifier];
        
    NSString *path = [NSString pathWithComponents:pathComponents];
    
    return path;
}

#pragma mark Initialization

- (id)initWithIdentifier:(NSString *)inIdentifier;
{
    if (!(self = [self initWithIdentifier:inIdentifier rootDirectory:nil])) {
        return nil;
    }
    
    return self;
}

- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootPath;
{
    if (!(self = [super initWithIdentifier:inIdentifier rootDirectory:[STPersistentCache defaultRootDirectoryForIdentifier:inIdentifier] modelPath:[STPersistentCache metadataModelPath]])) {
        return nil;
    }
    
    [self _updateFileCachePath];
    
    maximumFileCacheSize = STPersistentCacheDefaultMaximumFileCacheSize;
        
    return self;
}

- (void)dealloc;
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

#pragma mark Accessors

// From STDataStoreController. Make sure file cache path gets
// updated when root directory path changes.
- (void)setRootDirectory:(NSString *)inRootDirectory;
{
    [super setRootDirectory:inRootDirectory];
    [self _updateFileCachePath];
}

- (void)setMaximumMemoryCacheSize:(NSInteger)maximumMemoryCacheSize;
{
    memoryCache.totalCostLimit = maximumMemoryCacheSize;
}

- (NSInteger)maximumMemoryCacheSize;
{
    return memoryCache.totalCostLimit;
}

- (void)setMaximumFileCacheSize:(unsigned long long)inMaximumFileCacheSize;
{
    maximumFileCacheSize = inMaximumFileCacheSize;
    self.needsCacheTruncation = YES;
}

- (unsigned long long)totalFileCacheSize;
{
    if (!self.fileCachePath.length) {
        return 0;
    }
    
    NSFileManager *fm = [NSFileManager new];
    return [fm fileSizeAtPath:self.fileCachePath];
}

- (NSCache *)memoryCache;
{
    if (!memoryCache) {
        memoryCache = [[NSCache alloc] init];
        memoryCache.delegate = self;
    }
    
    return memoryCache;
}

- (void)setNeedsCacheTruncation:(BOOL)inNeedsCacheTruncation;
{
    // If we're not already set as needing cache truncation, we don't need
    // to kick off another truncation job.
    BOOL shouldStartDelayedTrunctation = !needsCacheTruncation && inNeedsCacheTruncation;
    
    needsCacheTruncation = inNeedsCacheTruncation;
    
    if (shouldStartDelayedTrunctation) {
        // This is designed to ensure that truncation jobs run no more than
        // once every 2 seconds, and only if something has actually been
        // added to the cache.
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, self.workerQueue, ^(void){
            // If we were set to no longer need cache truncation during the
            // delay, cancel the truncation job
            if (!needsCacheTruncation) {
                return;
            }
            
            [self _clearCacheItemsToFitMaxFileCacheSize];
            
            needsCacheTruncation = NO;
        });
    }
}

#pragma mark NSCacheDelegate

- (void)cache:(NSCache *)cache willEvictObject:(id)obj;
{
    //NSLog(@"Memory cache evicting object.");
}

#pragma mark Public Methods

- (void)setCacheData:(NSData *)inData forKey:(NSString *)inKey;
{
    [self setCacheData:inData forKey:(NSString *)inKey inBackground:NO didPersistBlock:NULL];
}

- (void)setCacheData:(NSData *)inData forKey:(NSString *)inKey inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
{
    [self setCacheData:inData forKey:inKey withAttributes:nil inBackground:inBackground didPersistBlock:didPersistBlock];
}

- (void)setCacheData:(NSData *)inData forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
{
    if (!inKey.length || !inData.length) {
        return;
    }
    
    void (^setDataBlock)(void) = ^{
        // Add the data to the memory cache
        [self.memoryCache setObject:inData forKey:inKey cost:[inData length]];
        [self setFileCacheData:inData forKey:inKey withAttributes:attributes inBackground:NO didPersistBlock:didPersistBlock];
    };

    if (inBackground) {
        dispatch_async(self.workerQueue, setDataBlock);
    } else {
        setDataBlock();
    }
}

- (void)setFileCacheData:(NSData *)inData forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
{
    if (!inKey.length || !inData.length) {
        return;
    }
    
    void (^setFileDataBlock)(void) = ^{
        // Add the data to the file cache (should overwrite)
        NSString *filePath = [self _fileCachePathForKey:inKey];
        NSFileManager *fm = [[NSFileManager alloc] init];
        if (![fm fileExistsAtPath:self.fileCachePath]) {
            [fm recursivelyCreatePath:self.fileCachePath];
        }
        
        if ([inData writeToFile:filePath atomically:NO])
        {
            NSURL *dataURL = [NSURL fileURLWithPath:filePath];
            [dataURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
        
        // Create a cache item or update the existing one
        STPersistentCacheItem *item = [self _findOrCreateCacheItemForKey:inKey];
        [item initializeWithData:inData forKey:inKey withAttributes:attributes];
        
        NSError *error = NULL;
        [self save];
        if (error) {
            NSLog(@"STPersistentCache Save Exception: %@", error);
        }
        
        if (didPersistBlock) {
            dispatch_sync(dispatch_get_main_queue(), didPersistBlock);
        }
        
        self.needsCacheTruncation = YES;
    };
    
    if (inBackground) {
        dispatch_async(self.workerQueue, setFileDataBlock);
    } else {
        setFileDataBlock();
    }
}

- (void)addCacheDataFromFileAtPath:(NSString *)inPath forKey:(NSString *)inKey;
{
    [self addCacheDataFromFileAtPath:inPath forKey:inKey inBackground:NO didPersistBlock:NULL];
}

- (void)addCacheDataFromFileAtPath:(NSString *)inPath forKey:(NSString *)inKey inBackground:(BOOL)inBackground didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
{
    [self addCacheDataFromFileAtPath:inPath forKey:inKey withAttributes:nil inBackground:inBackground didPersistBlock:didPersistBlock];
}

- (void)addCacheDataFromFileAtPath:(NSString *)inPath forKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes inBackground:(BOOL)inBackground  didPersistBlock:(STPersistentCacheBlock)didPersistBlock;
{
    if (!inKey.length || !inPath.length) {
        return;
    }
    
    void (^setDataBlock)(void) = ^{
        NSFileManager *fm = [[NSFileManager alloc] init];
        if (![fm fileExistsAtPath:inPath]) {
            return;
        }
        
        if (![fm fileExistsAtPath:self.fileCachePath]) {
            [fm recursivelyCreatePath:self.fileCachePath];
        }

        NSString *filePath = [self _fileCachePathForKey:inKey];
        NSError *moveError;
        BOOL success = [fm moveItemAtPath:inPath toPath:filePath error:&moveError];
        if (!success) {
            NSLog(@"Unable to add file at path %@ to cache due to error: %@", inPath, moveError);
            return;
        }
        
        // Create a cache item or update the existing one
        STPersistentCacheItem *item = [self _findOrCreateCacheItemForKey:inKey];
        [item initializeWithPath:inPath forKey:inKey withAttributes:nil];
        
        NSError *error = NULL;
        [[self threadContext] save:&error];
        if (error) {
            NSLog(@"STPersistentCache Save Exception: %@", error);
        }
        
        if (didPersistBlock) {
            dispatch_sync(dispatch_get_main_queue(), didPersistBlock);
        }
        
        self.needsCacheTruncation = YES;
    };
    
    if (inBackground) {
        dispatch_async(self.workerQueue, setDataBlock);
    } else {
        setDataBlock();
    }
}

- (void)removeCacheDataForKey:(NSString *)inKey;
{
    if (!inKey.length) {
        return;
    }

    dispatch_async(self.workerQueue, ^{
        STPersistentCacheItem *cacheItem = [self cacheItemForKey:inKey];
        if (cacheItem) {
            [self removeCacheItem:cacheItem];
        }
    });
}

- (void)removeCacheItem:(STPersistentCacheItem *)inCacheItem;
{
    if (!inCacheItem) {
        return;
    }
    
    NSString *key = inCacheItem.key;
    
    // Remove the data from the memory cache
    [self.memoryCache removeObjectForKey:key];
    
    // Remove the data from the file cache
    NSFileManager *fm = [NSFileManager new];
    NSString *filePath = [self _fileCachePathForKey:key];
    [fm removeItemAtPath:filePath error:NULL];
        
    // Delete the cache item
    [[self threadContext] deleteObject:inCacheItem];
}

- (NSDictionary *)attributesForKey:(NSString *)inKey;
{
    STPersistentCacheItem *item = [self cacheItemForKey:inKey];
    return item.attributes;
}

- (STPersistentCacheItem *)cacheItemForKey:(NSString *)inKey;
{
    if (!inKey.length) {
        return nil;
    }
    
    NSManagedObjectContext *threadContext = [self threadContext];
    
    NSEntityDescription *contextCacheItemEntity = [NSEntityDescription entityForName:STPersistentCacheItemEntityName inManagedObjectContext:threadContext];
    NSFetchRequest *contextItemFetchRequest = [[NSFetchRequest alloc] init];
    [contextItemFetchRequest setEntity:contextCacheItemEntity];
    
    NSPredicate *contextItemPredicate = [NSPredicate predicateWithFormat:@"%K == %@", STPersistentCacheItemCacheKeyModelKey, inKey];
    [contextItemFetchRequest setPredicate:contextItemPredicate];
    
    NSArray *contextItemResults = [threadContext executeFetchRequest:contextItemFetchRequest error:NULL];
    
    if (!contextItemResults.count) {
        return nil;
    }
    
    return [contextItemResults firstObject];
}

- (NSData *)cacheDataForKey:(NSString *)inKey;
{
    if (!inKey.length) {
        return nil;
    }
    
    NSData *memoryData = [self.memoryCache objectForKey:inKey];
    if (memoryData) {
        return memoryData;
    }
    
    NSData *fileData = [self fileCacheDataForKey:inKey];
    if (fileData.length) {
        [self.memoryCache setObject:fileData forKey:inKey cost:[fileData length]];
    }
   
    return fileData;
}

- (NSData *)fileCacheDataForKey:(NSString *)inKey;
{
    NSString *cachePath = [self _fileCachePathForKey:inKey];
    if (!cachePath) {
        return nil;
    }
    
    return [NSData dataWithContentsOfFile:cachePath];
}

- (void)clearCache;
{
    [self.memoryCache removeAllObjects];
    [self deletePersistentStore];
    [self _clearFileCache];
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (![fm fileExistsAtPath:self.fileCachePath]) {
        [fm recursivelyCreatePath:self.fileCachePath];
    }
}

- (BOOL)hasCacheDataForKey:(NSString *)inKey
{
    NSString *filePath = [self _fileCachePathForKey:inKey];
    NSFileManager *fm = [NSFileManager new];
    return [fm fileExistsAtPath:filePath];
}

#pragma mark Private Methods

- (void)_updateFileCachePath;
{
    self.fileCachePath = [self.rootDirectory stringByAppendingPathComponent:STPersistentCacheFileCacheSubdirectoryName];
}

- (NSString *)_fileCachePathForKey:(NSString *)inKey;
{
    if (!inKey.length || !self.fileCachePath.length) {
        return nil;
    }
    
    return [self.fileCachePath stringByAppendingPathComponent:[inKey MD5String]];
}

- (void)_clearFileCache;
{
    NSFileManager *fm = [NSFileManager new];
    [fm removeItemAtPath:self.fileCachePath error:NULL];
}

- (void)_clearCacheItemsToFitMaxFileCacheSize;
{
    unsigned long long cacheSize = self.totalFileCacheSize;
    if (cacheSize <= self.maximumFileCacheSize) {
        return;
    }
    
    NSUInteger spaceToClear = cacheSize - self.maximumFileCacheSize;
    [self _clearCacheItemsOfSize:spaceToClear];
}

- (void)_clearCacheItemsOfSize:(unsigned long long)inSize;
{
    if (!inSize) {
        return;
    } else if (inSize >= self.totalFileCacheSize) {
        [self clearCache];
        return;
    }
    
    NSManagedObjectContext *threadContext = [self threadContext];
    
    NSFetchRequest *cacheItemFetchRequest = [self _cacheItemsFetchRequest];
    cacheItemFetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:STPersistentCacheItemAddedTimestampModelKey ascending:YES]];
    
    NSError *fetchError = nil;
    NSArray *cacheItems = [threadContext executeFetchRequest:cacheItemFetchRequest error:&fetchError];
    if (!cacheItems)
    {
        return;
    }
    
    unsigned long long totalCleared = 0;
    
    for (STPersistentCacheItem *currentItem in cacheItems) {
        unsigned long long itemSize = currentItem.fileSize;

        [self removeCacheItem:currentItem];

        totalCleared += itemSize;
        
        if (totalCleared >= inSize) {
            break;
        }
    }
    
    NSError *error = NULL;
    [threadContext save:&error];
    if (error) {
        NSLog(@"STPersistentCache Save Exception: %@", error);
    }
}

#pragma mark Private Core Data Methods

- (STPersistentCacheItem *)_findOrCreateCacheItemForKey:(NSString *)inKey;
{
    STPersistentCacheItem *item = [self cacheItemForKey:inKey];
    if (!item) {
        NSManagedObjectContext *threadContext = [self threadContext];
        
        // Don't have an existing cache item, create one
        NSEntityDescription *entity = [NSEntityDescription entityForName:STPersistentCacheItemEntityName inManagedObjectContext:threadContext];
        item = [[STPersistentCacheItem alloc] initWithEntity:entity insertIntoManagedObjectContext:threadContext];
        item.key = inKey;
    }
    
    return item;
}

- (NSFetchRequest *)_cacheItemsFetchRequest;
{
    NSEntityDescription *cacheItemsEntity = [NSEntityDescription entityForName:STPersistentCacheItemEntityName inManagedObjectContext:[self threadContext]];
    
    NSFetchRequest *postIDFetchRequest = [[NSFetchRequest alloc] init];
    [postIDFetchRequest setEntity:cacheItemsEntity];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:STPersistentCacheItemAddedTimestampModelKey ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [postIDFetchRequest setSortDescriptors:sortDescriptors];
    
    return postIDFetchRequest;
}

@end


@implementation STPersistentCacheItem

@dynamic key;
@dynamic fileSize;
@dynamic addedTimestamp;
@dynamic updatedTimestamp;
@dynamic attributes;

#pragma mark Public Methods

- (void)initializeForKey:(NSString *)inKey withAttributes:(NSDictionary *)attributes;
{
    if (!inKey.length) {
        return;
    }
    
    self.key = inKey;
    
    if (!self.addedTimestamp) {
        self.addedTimestamp = [NSDate date];
    }
    
    self.updatedTimestamp = [NSDate date];
    self.attributes = attributes;
}

- (void)initializeWithData:(NSData *)inData forKey:(NSString *)inKey withAttributes:(NSDictionary *)inAttributes;
{
    if (!inData.length || !inKey.length) {
        return;
    }
    
    [self initializeForKey:inKey withAttributes:inAttributes];
    self.fileSize = inData.length;
}

- (void)initializeWithPath:(NSString *)inPath forKey:(NSString *)inKey withAttributes:(NSDictionary *)inAttributes;
{
    if (!inPath.length || !inKey.length) {
        return;
    }
    
    [self initializeForKey:inKey withAttributes:inAttributes];
    NSFileManager *fm = [NSFileManager new];
    self.fileSize = [fm fileSizeAtPath:inPath];
}

#pragma mark Accessors

- (void)setFileSize:(NSUInteger)inFileSize;
{
    [self setUnsignedInteger:inFileSize forKey:STPersistentCacheItemFileSizeModelKey];
}

- (NSUInteger)fileSize;
{
    return [self unsignedIntegerForKey:STPersistentCacheItemFileSizeModelKey];
}

@end

