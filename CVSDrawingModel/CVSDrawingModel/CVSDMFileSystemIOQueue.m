// CVSDMFileSystemIOQueue.m
// CVSDrawingModel
// Created by J on 10/25/13.
// Copyright (c) 2013 Canvas. All rights reserved.

#import "CVSDrawingModel.h"
#import "DQPapertrailLogger.h"

static const char CVSDMFileSystemIOQueue_Queue_Serial[] = "as.canv.CVSDMFileSystemIOQueue.serial";
static const char CVSDMFileSystemIOQueue_Queue_Concurrent[] = "as.canv.CVSDMFileSystemIOQueue.concurrent";

@interface CVSDMFileSystemIOQueue ()

/*
 @return the I/O queue's dispatch queue
 */
@property (nonatomic, readonly) dispatch_queue_t queue;

@end

@implementation CVSDMFileSystemIOQueue

@synthesize queue = _queue;

- (id)init
{
    assert(0 && "invalid initializer");
    return nil;
}

- (instancetype)initSerialQueue
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _queue = dispatch_queue_create(CVSDMFileSystemIOQueue_Queue_Serial, DISPATCH_QUEUE_SERIAL);
    if (!_queue) {
        assert(0 && "failed to create io queue");
        return nil;
    }
    return self;
}

+ (instancetype)serialQueue
{
    return [[self alloc] initSerialQueue];
}

- (instancetype)initConcurrentQueue
{
    self = [super init];
    if (!self) {
        return nil;
    }
    _queue = dispatch_queue_create(CVSDMFileSystemIOQueue_Queue_Concurrent, DISPATCH_QUEUE_CONCURRENT);
    if (!_queue) {
        assert(0 && "failed to create io queue");
        return nil;
    }
    return self;
}

+ (instancetype)concurrentQueue
{
    return [[self alloc] initConcurrentQueue];
}

- (void)dispatch:(CVSDMFileSystemIOQueueTask)pTask
{
    assert(pTask);
    dispatch_async(self.queue, pTask);
}

- (void)removeItemAtURL:(NSURL *)pURL
{
    __strong NSURL * url = pURL.copy;
    assert(url);
    [self dispatch:^{
        NSError * outError = nil;
        if (![[NSFileManager new] removeItemAtURL:url error:&outError]) {
            if (outError) {
                [DQPapertrailLogger component:@"cvsdmfilesystemioqueue" category:@"remove-item-failed" error:outError dataBlock:^(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"url": [url absoluteString] ?: [NSNull null]};
                }];
            }
        }
    }];
}

@end
