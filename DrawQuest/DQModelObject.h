//
//  DQModelObject.h
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "Mantle.h"

typedef enum {
    DQImageKeyOriginal,
    DQImageKeyGallery,
    DQImageKeyHomePageFeatured,
    DQImageKeyArchive,
    DQImageKeyActivity,
    DQImageKeyQuestTemplate,
    DQImageKeyCameraRoll,
    DQImageKeyPhoneGallery,
} DQImageKey;

@interface DQModelObject : MTLModel

@property (nonatomic, readonly, copy) NSDate *timestamp;
@property (nonatomic, readonly, copy) NSString *serverID;
@property (nonatomic, readonly, copy) NSDictionary *content;

- (NSString *)equalityIdentifier;

- (NSString *)imageURLForKey:(DQImageKey)inImageKey;

@end
