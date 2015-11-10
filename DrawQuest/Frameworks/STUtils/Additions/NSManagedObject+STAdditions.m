//
//  NSManagedObject+STAdditions.m
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSManagedObject+STAdditions.h"


@implementation NSManagedObject (STAdditions)

#pragma mark Primitive Accessors

- (BOOL)boolForKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    return [value boolValue];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:@(value) forKey:key];
    [self didChangeValueForKey:key];
}

- (unsigned int)unsignedIntForKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    return [value unsignedIntValue];
}

- (void)setUnsignedInt:(unsigned int)value forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:@(value) forKey:key];
    [self didChangeValueForKey:key];
}

- (NSUInteger)unsignedIntegerForKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    return [value unsignedIntegerValue];
}

- (void)setUnsignedInteger:(NSUInteger)value forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:@(value) forKey:key];
    [self didChangeValueForKey:key];
}

- (double)doubleForKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    NSNumber *value = [self primitiveValueForKey:key];
    [self didAccessValueForKey:key];
    
    return [value doubleValue];
}

- (void)setDouble:(double)value forKey:(NSString *)key;
{
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:@(value) forKey:key];
    [self didChangeValueForKey:key];
}

- (NSData *)dataForKey:(NSString *)inKey;
{
    [self willAccessValueForKey:inKey];
    NSData *value = [self primitiveValueForKey:inKey];
    [self didAccessValueForKey:inKey];
    
    return value;
}

- (void)setData:(NSData *)value forKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    [self setPrimitiveValue:value forKey:key];
    [self didAccessValueForKey:key];
}

#if TARGET_OS_IPHONE

- (CGSize)sizeForKey:(NSString *)inKey;
{
    [self willAccessValueForKey:inKey];
    NSValue *value = [self primitiveValueForKey:inKey];
    [self didAccessValueForKey:inKey];
    
    return [value CGSizeValue];
}

- (void)setSize:(CGSize)value forKey:(NSString *)key;
{
    [self willAccessValueForKey:key];
    [self setPrimitiveValue:[NSValue valueWithCGSize:value] forKey:key];
    [self didAccessValueForKey:key];
}

#endif

@end
