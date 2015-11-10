//
//  STRandomization.m
//  Hipflask
//
//  Created by Buzz Andersen on 4/12/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "STRandomization.h"


BOOL STRandomCoinFlip(void)
{
    return STRandomIntegerWithMax(2);
}

NSInteger STRandomIntegerWithMax(NSInteger max)
{
    srandomdev();
    
    if (max == 0) {
        return random();
    }
    
    return (random() % max);
}
