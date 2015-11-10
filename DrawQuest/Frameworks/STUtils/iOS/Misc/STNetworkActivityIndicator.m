//
//  STNetworkActivityIndicator.m
//
//  Created by Buzz Andersen on 3/16/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "STNetworkActivityIndicator.h"

@implementation STNetworkActivityIndicator

+ (STNetworkActivityIndicator *)sharedIndicator;
{
    static STNetworkActivityIndicator *sharedInstance = nil;
    
    if (!sharedInstance) {
        sharedInstance = [[[self class] alloc] init];
    }
    
    return sharedInstance;
}

- (void)increment;
{
	@synchronized (self) {
		count++;
		if (count > 0) {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		}
	}    
}

- (void)decrement;
{
	@synchronized (self) {
		count--;
		
		if (count < 0) {
			count = 0;
		}
		
		if (count <= 0) {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		}
	}
}

@end
