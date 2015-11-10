//
//  NSArray+STAdditions.m
//
//  Created by Buzz Andersen on 2/19/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "NSArray+STAdditions.h"
#import "NSObject+STAdditions.h"
#import "NSString+STAdditions.h"
#import "STRandomization.h"

@implementation NSArray (STAdditions)

- (id)objectAtRandomIndex;
{
    if (!self.count) {
        return nil;
    }
    
    if (self.count < 2) {
        return [self objectAtIndex:0];
    }
    
    return [self objectAtIndex:STRandomIntegerWithMax(self.count)];
}

- (NSString *)URLEncodedStringValue;
{
	if (self.count < 1) {
        return @"";
    }
        
	BOOL appendAmpersand = NO;
    
	NSMutableString *parameterString = [[NSMutableString alloc] init];
    
	for (id currentValue in self) {
		NSString *stringValue = [currentValue URLParameterStringValue];
        
		if (stringValue != nil) {
			if (appendAmpersand) {
				[parameterString appendString:@"&"];
			}
            
			NSString *escapedStringValue = [stringValue stringByEscapingQueryParameters];
            
			[parameterString appendFormat:@"%@", escapedStringValue];
		}
        
		appendAmpersand = YES;
	}
    
	return [parameterString autorelease];
}

@end
