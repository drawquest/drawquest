//
//  STNetworkActivityIndicator.h
//
//  Created by Buzz Andersen on 3/16/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface STNetworkActivityIndicator : NSObject {
    NSInteger count;
}

+ (STNetworkActivityIndicator *)sharedIndicator;
- (void)increment;
- (void)decrement;

@end
