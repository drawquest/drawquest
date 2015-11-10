//
//  CVSUniqueObjectCache.h
//  DrawQuest
//
//  Created by Justin Carlson on 10/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 @brief the CVSUniqueObjectCacheObjectInsertionPolicy defines a policy for objects when inserted into a cache.
 */
typedef NS_ENUM(uint8_t, CVSUniqueObjectCacheObjectInsertionPolicy) {
    /** @constant objects are retained */
    CVSUniqueObjectCacheObjectInsertionPolicyRetain,
    /** @constant objects are copied */
    CVSUniqueObjectCacheObjectInsertionPolicyCopy
};

/**
 @class the unique object cache is a simple homogenous collection which contains a set of objects. objects this represents should generally be immutable (and copied where possible).
 @details this type is not thread safe. this class presently offers no mutable/immutable distinction.
 */
@interface CVSUniqueObjectCache : NSObject <NSCopying,NSFastEnumeration>

/** @method designated initializer */
- (instancetype)initWithObjectType:(Class)pObjectType objectInsertionPolicy:(CVSUniqueObjectCacheObjectInsertionPolicy)pObjectInsertionPolicy;
/** @method designated initializer */
- (instancetype)initWithObjectType:(Class)pObjectType objectInsertionPolicy:(CVSUniqueObjectCacheObjectInsertionPolicy)pObjectInsertionPolicy objects:(id<NSFastEnumeration>)pObjects;

/** @method returns an NSSet containing all elements */
- (NSSet *)allObjects;

/** @method adds @p pObject to the set */
- (void)addObject:(id)pObject;
/** @method adds all objects in @p pObjects into the collection */
- (void)addObjects:(id<NSFastEnumeration>)pObjects;

/** @method removes @p pObject from the set */
- (void)removeObject:(id)pObject;

/** @return the object equal to pObject, nil if not found */
- (id)member:(id)pObject;

/** @return the object in the collection equal to @p pObject, adding it if not found. */
- (id)uniqueObject:(id)pObject;

/** @return the input array, populated with the unique values, added to the cache as needed. */
- (NSArray *)uniqueArrayWithArray:(NSArray *)pArray;

@end
