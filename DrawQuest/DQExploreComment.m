//
//  DQExploreComment.m
//  DrawQuest
//
//  Created by Dirk on 4/15/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQExploreComment.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"

@implementation DQExploreComment

- (id)initWithJSONDictionary:(NSDictionary *)inDictionary
{
    self = [super init];
    if (self) {
        _commentID = [[inDictionary dq_serverID] copy];
        _questID = [[inDictionary dq_commentQuestID] copy];
        _content = [[inDictionary dq_content] copy];
    }
    
    return self;
}

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
        case DQImageKeyPhoneGallery:
            key = @"iphone_gallery";
            break;
        default:
            break;
    }
    
    return [self.content dictionaryForKey:key].dq_imageURL;
}


@end
