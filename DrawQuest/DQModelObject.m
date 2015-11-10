//
//  DQModelObject.m
//  DrawQuest
//
//  Created by Buzz Andersen on 10/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQModelObject.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "STUtils.h"

@interface DQModelObject ()

@property (nonatomic, readwrite, copy) NSDate *timestamp;
@property (nonatomic, readwrite, copy) NSString *serverID;
@property (nonatomic, readwrite, copy) NSDictionary *content;

@end

@implementation DQModelObject

- (NSUInteger)hash
{
	NSUInteger value = [self.serverID hash];
    return value;
}

- (NSString *)equalityIdentifier
{
    return self.serverID;
}

- (BOOL)isEqual:(DQModelObject *)model
{
    return self == model || ([model isMemberOfClass:[self class]] && [[self equalityIdentifier] isEqualToString:[model equalityIdentifier]]);
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

