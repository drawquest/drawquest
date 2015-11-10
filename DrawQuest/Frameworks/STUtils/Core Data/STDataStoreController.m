//
//  STDataStoreController.m
//
//  Created by Buzz Andersen on 3/24/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "STDataStoreController.h"
#import "STUtils.h"

// Notifications
NSString *STDataStoreControllerWillClearDatabaseNotification = @"STDataStoreControllerWillClearDatabaseNotification";
NSString *STDataStoreControllerDidClearDatabaseNotification = @"STDataStoreControllerDidClearDatabaseNotification";
NSString *STDataStoreControllerThreadContextKey = @"STDataStoreControllerThreadContextKey";


@interface STDataStoreController ()

@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSManagedObjectContext *mainContext;
@property (nonatomic, retain) NSString *persistentStorePath;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSManagedObjectContext *)_contextForThread:(NSThread *)inThread;
- (NSString *)_currentThreadContextKey;
- (void)_updatePersistentStorePath;
- (void)_updatePersistentStoreCoordinator;

@end


@implementation STDataStoreController

@synthesize identifier;
@synthesize rootDirectory;
@synthesize managedObjectModelPath;
@synthesize persistentStorePath;
@synthesize managedObjectModel;
@synthesize mainContext;
@synthesize persistentStoreCoordinator;
@synthesize mergePolicy;

#pragma mark Class

+ (NSString *)defaultRootDirectory;
{
    NSMutableArray *pathComponents = [[NSMutableArray alloc] init];

    // If we're on a Mac, include the app name in the
    // application support path.
    NSFileManager *fm = [[NSFileManager new] autorelease];
#if !TARGET_OS_IPHONE
    [pathComponents addObject:[fm applicationSupportPathIncludingAppName]];
#else
    [pathComponents addObject:[fm applicationSupportPath]];
#endif
    
    [pathComponents addObject:NSStringFromClass([self class])];
    
    NSString *path = [NSString pathWithComponents:pathComponents];
    [pathComponents release];
    
    return path;
}

#pragma mark Initialization

- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootDirectory;
{
    if (!(self = [self initWithIdentifier:inIdentifier rootDirectory:inRootDirectory modelPath:nil])) {
        return nil;
    }
    
    return self;
}

- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootDirectory modelPath:(NSString *)inModelPath;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    managedObjectModelPath = [inModelPath retain];
    
    identifier = [inIdentifier retain];
    
    rootDirectory = inRootDirectory.length ? [inRootDirectory retain] : [[[self class] defaultRootDirectory] retain];
    
    [self _updatePersistentStorePath];
    
    mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    
    workerQueue = NULL;

#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:UIApplicationWillResignActiveNotification object:nil];
#elif TARGET_OS_MAC
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:NSApplicationWillTerminateNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:NSApplicationWillResignActiveNotification object:nil];
#endif
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self reset];
    
    [managedObjectModelPath release];
    [identifier release];
    [rootDirectory release];
    [persistentStorePath release];
    [managedObjectModel release];

    [super dealloc];
}

#pragma mark Accessors

- (void)setManagedObjectModelPath:(NSString *)inManagedObjectModelPath;
{
    if (managedObjectModelPath && ![inManagedObjectModelPath isEqualToString:managedObjectModelPath]) {
        [self reset];
    }
    
    [inManagedObjectModelPath retain];
    [managedObjectModelPath release];
    managedObjectModelPath = inManagedObjectModelPath;
}

- (void)setPersistentStorePath:(NSString *)inPersistentStorePath;
{
    if ([inPersistentStorePath isEqualToString:persistentStorePath]) {
        return;
    }
    
    [inPersistentStorePath retain];
    [persistentStorePath release];
    persistentStorePath = inPersistentStorePath;
    
    [self reset];
}

- (void)setIdentifier:(NSString *)inIdentifier;
{
    if ([inIdentifier isEqualToString:identifier]) {
        return;
    }
    
    [inIdentifier retain];
    [identifier release];
    identifier = inIdentifier;
    
    [self _updatePersistentStorePath];
}

- (void)setRootDirectory:(NSString *)inRootDirectory;
{    
    if ([inRootDirectory isEqualToString:rootDirectory]) {
        return;
    }
    
    [inRootDirectory retain];
    [rootDirectory retain];
    rootDirectory = inRootDirectory;

    [self _updatePersistentStorePath];
}

- (NSManagedObjectModel *)managedObjectModel;
{
    if (!managedObjectModel)
    {
        NSFileManager *fm = [[NSFileManager new] autorelease];
        if (self.managedObjectModelPath.length && [fm fileExistsAtPath:self.managedObjectModelPath isDirectory:NULL])
        {
            managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.managedObjectModelPath]];
        }
    }
    return managedObjectModel;
}

- (void)setMergePolicy:(NSMergePolicy *)inMergePolicy;
{
    mergePolicy = inMergePolicy;
    self.mainContext.mergePolicy = inMergePolicy;
}

- (dispatch_queue_t)workerQueue;
{
    if (!workerQueue) {
        NSString *workerName = [NSString stringWithFormat:@"com.systemoftouch.%@.WorkerQueue", NSStringFromClass([self class])];
        workerQueue = dispatch_queue_create([workerName UTF8String], NULL);
    }
    
    return workerQueue;
}

#pragma mark Core Data Boilerplate

- (NSManagedObjectContext *)mainContext;
{
    NSManagedObjectContext *result = nil;
    @synchronized(self)
    {
        if (!mainContext)
        {
            mainContext = [self newManagedObjectContext];
        }
        result = mainContext;
    }
    
    return result;
}

- (NSManagedObjectContext *)threadContext;
{
    return [self _contextForThread:[NSThread currentThread]];
}

- (NSManagedObjectContext *)_contextForThread:(NSThread *)inThread;
{
    if ([inThread isMainThread]) {
        return self.mainContext;
    }
    
    NSMutableDictionary *threadDictionary = inThread.threadDictionary;
    NSString *currentThreadContextKey = [self _currentThreadContextKey];
    NSManagedObjectContext *threadContext = [threadDictionary objectForKey:currentThreadContextKey];
    
    if (threadContext && threadContext.persistentStoreCoordinator != persistentStoreCoordinator) {
        [threadDictionary removeObjectForKey:currentThreadContextKey];
        threadContext = nil;
    }

    if (!threadContext) {
        threadContext = [self newManagedObjectContext];
        [threadDictionary setObject:threadContext forKey:currentThreadContextKey];
        [threadContext release];
    }
    
    if (inThread == [NSThread mainThread]) {
        threadContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    } else {
        threadContext.mergePolicy = self.mergePolicy;
    }
    
    return threadContext;
}

- (NSString *)_currentThreadContextKey;
{
    return [NSString stringWithFormat:@"%@-%@", STDataStoreControllerThreadContextKey, NSStringFromClass([self class])];
}

- (void)_updatePersistentStoreCoordinator;
{
    // Create the directory for the persistent store if it doesn't exist yet.
    NSFileManager *fm = [[NSFileManager new] autorelease];
    if (![fm fileExistsAtPath:self.rootDirectory]) {
        [fm recursivelyCreatePath:self.rootDirectory];
    }
    
    // Set up the persistent store coordinator.
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel] autorelease];
    
    NSURL *storeURL = [NSURL fileURLWithPath:self.persistentStorePath];
    NSError *error = nil;
    NSDictionary *optionsDictionary = @{NSMigratePersistentStoresAutomaticallyOption : @(YES), NSInferMappingModelAutomaticallyOption : @(YES), NSSQLitePragmasOption : @{ @"journal_mode" : @"DELETE" }};

    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:optionsDictionary error:&error]) {
        // If we couldn't load the persistent store (likely due to database incompatibility)
        // delete the existing database and try again.
        [self deletePersistentStore];
        
        if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:optionsDictionary error:&error]) {
            NSLog(@"Could not load database after clearing! Error: %@, %@", error, [error userInfo]);
            exit(1);
        }
    }
    
    @synchronized(self)
    {
        self.persistentStoreCoordinator = coordinator;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mergeThreadContextChanges:) name:NSManagedObjectContextDidSaveNotification object:nil];
    }
}
    
#pragma mark Public Methods

- (void)save;
{
    NSError *error = nil;
    BOOL result = [[self threadContext] save:&error];
    if (!result)
    {
        NSLog(@"STDataStoreController Save Exception: %@", error);
    }
}

#pragma mark Private Methods

- (NSManagedObjectContext *)newManagedObjectContext;
{
    if (!self.persistentStoreCoordinator) {
        [self _updatePersistentStoreCoordinator];
    }

    NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] init];
    [newContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
    return newContext;
}

- (void)reset;
{
    @synchronized(self)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];

        // Force the queue to complete before releasing the queue
        // by waiting until an empty block finishes
        if (workerQueue) {
            dispatch_sync(workerQueue, ^{ });
            dispatch_release(workerQueue);
            workerQueue = NULL;
        }

        // Release the main context, managed object model, and
        // persistent store coordinator
        [mainContext release];
        mainContext = nil;

        [managedObjectModel release];
        managedObjectModel = nil;

        [persistentStoreCoordinator release];
        persistentStoreCoordinator = nil;
    }
}

- (void)deletePersistentStore;
{
    // Clear out Core Data stack
    [self reset];
    
    if (!self.persistentStorePath.length) {
        return;
    }

    // Remove persistent store file
    [[NSNotificationCenter defaultCenter] postNotificationName:STDataStoreControllerWillClearDatabaseNotification object:self];
    
    NSFileManager *fm = [[NSFileManager new] autorelease];
    [fm removeItemAtPath:self.persistentStorePath error:NULL];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:STDataStoreControllerDidClearDatabaseNotification object:self];
}

- (void)_mergeThreadContextChanges:(NSNotification *)inNotification;
{
    NSManagedObjectContext *changedContext = inNotification.object;
    if (!self.persistentStoreCoordinator || changedContext.persistentStoreCoordinator != self.persistentStoreCoordinator) {
        return;
    }
        
   void (^handleChangesBlock)(void) = ^{
        [self.mainContext mergeChangesFromContextDidSaveNotification:inNotification];
    };
    
    if (changedContext == self.mainContext) {
        handleChangesBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), handleChangesBlock);
    }
}

- (void)_updatePersistentStorePath;
{
    NSString *dataStoreIdentifier = self.identifier;
    if (!dataStoreIdentifier) {
        dataStoreIdentifier = NSStringFromClass([self class]);
    }
    
    @synchronized(self)
    {
        self.persistentStorePath = [self.rootDirectory stringByAppendingPathComponent:[dataStoreIdentifier stringByAppendingPathExtension:@"sqlite"]];
    }
}

@end
