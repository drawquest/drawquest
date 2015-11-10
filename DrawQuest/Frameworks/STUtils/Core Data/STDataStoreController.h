//
//  STDataStoreController.h
//
//  Created by Buzz Andersen on 3/24/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

extern NSString *STDataStoreControllerWillClearDatabaseNotification;
extern NSString *STDataStoreControllerDidClearDatabaseNotification;


@interface STDataStoreController : NSObject {
    NSString *identifier;
    NSString *rootDirectory;
    NSString *managedObjectModelPath;
    
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;

    NSMergePolicy *mergePolicy;
    
    dispatch_queue_t workerQueue;
}

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *managedObjectModelPath;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSString *rootDirectory;
@property (nonatomic, retain, readonly) NSString *persistentStorePath;

@property (nonatomic, retain, readonly) NSManagedObjectContext *mainContext;

@property (nonatomic, assign) NSMergePolicy *mergePolicy;
@property (nonatomic, assign, readonly) dispatch_queue_t workerQueue;

// Class Methods
+ (NSString *)defaultRootDirectory;

// Initialization

// designated initializer
- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootDirectory modelPath:(NSString *)inModelPath;

// convenience initializer
- (id)initWithIdentifier:(NSString *)inIdentifier rootDirectory:(NSString *)inRootDirectory;

- (id)init MSDesignatedInitializer(initWithIdentifier:rootDirectory:modelPath:);

// Managed Object Contexts
- (NSManagedObjectContext *)newManagedObjectContext;
- (NSManagedObjectContext *)threadContext;

// Reset/Clear Database
- (void)save;
- (void)reset;
- (void)deletePersistentStore;

@end
