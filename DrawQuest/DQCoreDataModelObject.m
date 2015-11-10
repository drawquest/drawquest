//
//  DQModelObject.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQCoreDataModelObject.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"


@implementation DQCoreDataModelObject

@dynamic timestamp;
@dynamic updatedTimestamp;
@dynamic serverID;
@dynamic content;
@dynamic identifier;

#pragma mark Initialization

- (void)initializeWithJSONDictionary:(NSDictionary *)inDictionary
{
    self.serverID = inDictionary.dq_serverID;
    self.timestamp = inDictionary.dq_timestamp;
//    self.updatedTimestamp = [NSDate date]; // updatedTimestamp is never read
    self.content = inDictionary.dq_content;
}

#pragma mark NSManagedObject

- (void)awakeFromInsert
{
    self.identifier = [NSString UUIDString];
}

#pragma mark Accessors

- (NSString *)imageURLForKey:(DQImageKey)inImageKey
{
    NSString *key = @"gallery";
    switch (inImageKey) {
        case DQImageKeyOriginal:
            key = @"original";
            break;
        case DQImageKeyHomePageFeatured:
            key = @"homepage_featured";
            break;
        case DQImageKeyArchive:
            key = @"archive";
            break;
        case DQImageKeyQuestTemplate:
            key = @"editor_template";
            break;
        case DQImageKeyCameraRoll:
            key = @"camera_roll";
            break;
        default:
            break;
    }
    
    return [self.content dictionaryForKey:key].dq_imageURL;
}

@end

