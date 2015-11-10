//
//  DQModelObject+DataStore.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-09-26.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQModelObject.h"
#import "YapCollectionsDatabaseTransaction.h"

#define DQModelObjectSetProperty(property, newValue, changed) do\
{\
    id o = self.property;\
    id n = newValue;\
    if (!(o ? [o isEqual:n] : !n))\
    {\
        self.property = n;\
        changed = YES;\
    }\
} while (0)

#define DQModelObjectSetPrimProp(type, property, newValue, changed) do\
{\
type n = newValue;\
if (self.property != n)\
{\
self.property = n;\
changed = YES;\
}\
} while (0)

@interface DQModelObject (DataStore)

+ (NSString *)yapCollectionName;
- (NSString *)yapCollectionKey;

- (instancetype)initWithServerID:(NSString *)serverID;

- (NSString *)serverIDFromJSONDictionary:(NSDictionary *)inDictionary;
- (BOOL)initializeWithJSONDictionary:(NSDictionary *)inDictionary;

+ (instancetype)objectForKey:(NSString *)key inTransaction:(YapCollectionsDatabaseReadTransaction *)transaction;
- (void)saveInTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;
- (void)deleteInTransaction:(YapCollectionsDatabaseReadWriteTransaction *)transaction;

@end
