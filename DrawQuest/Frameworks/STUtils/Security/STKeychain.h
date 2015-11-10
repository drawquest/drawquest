//
//  STKeychain.h
//
//  Created by Buzz Andersen on 3/7/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface STKeychain : NSObject {
    
}

+ (NSString *)getPasswordForUsername:(NSString *)username andServiceName:(NSString *)serviceName error:(NSError **)error;
+ (BOOL)storeUsername:(NSString *)username andPassword:(NSString *)password forServiceName:(NSString *)serviceName updateExisting:(BOOL)updateExisting error:(NSError **)error;
+ (BOOL)deleteItemForUsername:(NSString *)username andServiceName:(NSString *)serviceName error:(NSError **)error;

@end
