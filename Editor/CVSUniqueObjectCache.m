//
//  CVSUniqueObjectCache.m
//  DrawQuest
//
//  Created by Justin Carlson on 10/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSUniqueObjectCache.h"

@interface CVSUniqueObjectCache ()

@property (nonatomic, readonly) NSMutableSet * objects;
@property (nonatomic, readonly) Class objectType;
@property (nonatomic, readonly) CVSUniqueObjectCacheObjectInsertionPolicy objectInsertionPolicy;

@end

@implementation CVSUniqueObjectCache

- (instancetype)initWithObjectType:(Class)pObjectType objectInsertionPolicy:(CVSUniqueObjectCacheObjectInsertionPolicy)pObjectInsertionPolicy objects:(id<NSFastEnumeration>)pObjects
{
    assert(pObjectType);
    self = [super init];
    if (self == nil) {
        return nil;
    }
    _objects = [NSMutableSet set];
    _objectType = pObjectType;
    _objectInsertionPolicy = pObjectInsertionPolicy;
    if (pObjectInsertionPolicy == CVSUniqueObjectCacheObjectInsertionPolicyCopy) {
        assert([_objectType conformsToProtocol:@protocol(NSCopying)] && "class is not copyable");
    }
    [self addObjects:pObjects];
    return self;
}

- (instancetype)initWithObjectType:(Class)pObjectType objectInsertionPolicy:(CVSUniqueObjectCacheObjectInsertionPolicy)pObjectInsertionPolicy
{
    return [self initWithObjectType:pObjectType objectInsertionPolicy:pObjectInsertionPolicy objects:@[]];
}

- (id)copyWithZone:(NSZone *)pZone
{
    CVSUniqueObjectCache * tmp = [[[self class] allocWithZone:pZone] initWithObjectType:self.objectType objectInsertionPolicy:self.objectInsertionPolicy];
    if (self.objects.count) {
        [tmp addObjects:self.objects];
    }
    return tmp;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)pState objects:(id __unsafe_unretained [])pBuffer count:(NSUInteger)pLength
{
    return [self.objects countByEnumeratingWithState:pState objects:pBuffer count:pLength];
}

- (NSSet *)allObjects
{
    return self.objects.copy;
}

- (id)member:(id)pObject
{
    return [self.objects member:pObject];
}

- (void)imp_insertObject:(id)pObject
{
    assert(pObject);
    assert([pObject isKindOfClass:self.objectType] && "attempt to insert object of the wrong type into a homogenous collection");
    id member = [self member:pObject];
    if (member != nil) {
        return;
    }
    switch (self.objectInsertionPolicy) {
        case CVSUniqueObjectCacheObjectInsertionPolicyRetain :
            member = pObject;
            break;
        case CVSUniqueObjectCacheObjectInsertionPolicyCopy :
            member = [pObject copy];
            break;
    }
    assert(member);
    [self.objects addObject:member];
}

- (void)addObject:(id)pObject
{
    [self imp_insertObject:pObject];
}

- (void)removeObject:(id)pObject
{
    [self.objects removeObject:pObject];
}

- (void)addObjects:(id<NSFastEnumeration>)pObjects
{
    for (id at in pObjects) {
        [self imp_insertObject:at];
    }
}

- (id)uniqueObject:(id)pObject
{
    assert(pObject);
    id result = [self member:pObject];
    if (result == nil) {
        [self imp_insertObject:pObject];
        result = [self member:pObject];
    }
    assert(result);
    return result;
}

- (NSArray *)uniqueArrayWithArray:(NSArray *)pArray
{
    if (0 == pArray.count) {
        return [pArray copy];
    }
    NSMutableArray * results = [NSMutableArray new];
    for (id at in pArray) {
        [results addObject:[self uniqueObject:at]];
    }
    return [results copy];
}

@end
