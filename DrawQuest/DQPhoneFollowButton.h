//
//  DQPhoneFollowButton.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-01.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQButton.h"

@interface DQPhoneFollowButton : DQButton

@property (nonatomic, copy) NSString *username;

- (void)prepareForReuse;

@end
