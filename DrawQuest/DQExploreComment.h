//
//  DQExploreComment.h
//  DrawQuest
//
//  Created by Dirk on 4/15/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DQModelObject.h"

@interface DQExploreComment : NSObject

@property (nonatomic, copy) NSString *commentID;
@property (nonatomic, copy) NSString *questID;
@property (nonatomic, copy) NSDictionary *content;

// designated initializer
- (id)initWithJSONDictionary:(NSDictionary *)inDictionary;

- (id)init MSDesignatedInitializer(initWithJSONDictionary:);

- (NSString *)imageURLForKey:(DQImageKey)inImageKey;

@end
