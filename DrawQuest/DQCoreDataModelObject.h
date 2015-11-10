//
//  DQModelObject.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DQModelObject.h"

@interface DQCoreDataModelObject : NSManagedObject

@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, strong) NSDate *updatedTimestamp;
@property (nonatomic, strong) NSString *serverID;
@property (nonatomic, strong) NSDictionary *content;
@property (nonatomic, strong) NSString *identifier;

- (void)initializeWithJSONDictionary:(NSDictionary *)inDictionary;

- (NSString *)imageURLForKey:(DQImageKey)inImageKey;

@end
