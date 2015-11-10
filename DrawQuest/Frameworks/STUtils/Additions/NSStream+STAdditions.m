//
//  NSStream+STAdditions.m
//  Hipflask
//
//  Created by Buzz Andersen on 4/10/12.
//  Copyright (c) 2012 System of Touch. All rights reserved.
//

#import "NSStream+STAdditions.h"


@implementation NSStream (STAdditions)

+ (void)createBoundInputStream:(NSInputStream **)inputStreamPointer outputStream:(NSOutputStream **)outputStreamPointer withBufferSize:(NSUInteger)bufferSize;
{
    if ((inputStreamPointer != NULL) || (outputStreamPointer != NULL)) {
        return;
    }
    
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    CFStreamCreateBoundPair(NULL, 
                            ((inputStreamPointer != nil) ? &readStream : NULL),
                            ((outputStreamPointer != nil) ? &writeStream : NULL), 
                            (CFIndex) bufferSize);
    
    if (inputStreamPointer != NULL) {
        *inputStreamPointer  = [(id)readStream autorelease];
    }
    if (outputStreamPointer != NULL) {
        *outputStreamPointer = [(id)writeStream autorelease];
    }
}

@end
