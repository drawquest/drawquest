//
//  NSStream+STAdditions.h
//  Hipflask
//
//  Created by Buzz Andersen on 4/10/12.
//  Copyright (c) 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSStream (STAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPointer outputStream:(NSOutputStream **)outputStreamPointer withBufferSize:(NSUInteger)bufferSize;

@end
