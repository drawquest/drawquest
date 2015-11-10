//
//  NSObject+STAdditions.m
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSObject+STAdditions.h"
#import "NSArray+STAdditions.h"
#import "NSDate+STAdditions.h"
#import "NSDictionary+STAdditions.h"

@implementation NSObject (STAdditions)

#pragma mark URL Parameter Strings

- (NSString *)URLParameterStringValue;
{
	NSString *stringValue = nil;
	
	if ([self isKindOfClass:[NSString class]]) {
		stringValue = (NSString *)self;
	} else if ([self isKindOfClass:[NSNumber class]]) {
		stringValue = [(NSNumber *)self stringValue];
	} else if ([self isKindOfClass:[NSDate class]]) {
		stringValue = [(NSDate *)self HTTPTimeZoneHeaderString];
	} else if ([self isKindOfClass:[NSDictionary class]]) {
        stringValue = [(NSDictionary *)self URLEncodedStringValue];
    } else if ([self isKindOfClass:[NSArray class]]) {
        stringValue = [(NSArray *)self URLEncodedStringValue];
    }
    
	return stringValue;
}

#pragma mark Perform Selector

- (void)performSelectorOnRunloopCycle:(SEL)selector;
{
    [self performSelector:selector withObject:nil afterDelay:0.0];
}

- (void)performSelectorOnRunloopCycle:(SEL)selector withObject:(id)obj1;
{
    [self performSelector:selector withObject:obj1 afterDelay:0.0];
}

@end
