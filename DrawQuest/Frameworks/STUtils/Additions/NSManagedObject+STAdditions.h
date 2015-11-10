//
//  NSManagedObject+STAdditions.h
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObject (STAdditions)

// Primitive Accessors
- (BOOL)boolForKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

- (unsigned int)unsignedIntForKey:(NSString *)key;
- (void)setUnsignedInt:(unsigned int)value forKey:(NSString *)key;

- (NSUInteger)unsignedIntegerForKey:(NSString *)key;
- (void)setUnsignedInteger:(NSUInteger)value forKey:(NSString *)key;

- (double)doubleForKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;

- (NSData *)dataForKey:(NSString *)inKey;
- (void)setData:(NSData *)value forKey:(NSString *)key;

#if TARGET_OS_IPHONE
- (CGSize)sizeForKey:(NSString *)inKey;
- (void)setSize:(CGSize)value forKey:(NSString *)key;
#endif

@end
