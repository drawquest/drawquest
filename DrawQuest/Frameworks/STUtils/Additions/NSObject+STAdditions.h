//
//  NSObject+STAdditions.h
//
//  Created by Buzz Andersen on 12/29/09.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (STAdditions)

// URL Parameter Strings
- (NSString *)URLParameterStringValue;

// Perform Selector
- (void)performSelectorOnRunloopCycle:(SEL)selector;
- (void)performSelectorOnRunloopCycle:(SEL)selector withObject:(id)obj1;

@end
