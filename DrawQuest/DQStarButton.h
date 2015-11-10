//
//  DQStarButton.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-07.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQButton.h"
#import "DQStarConstants.h"

@protocol DQStarButtonDelegate <NSObject>
@optional
- (void)starButtonValueChanged;

@end

@interface DQStarButton : DQButton

@property (nonatomic, weak) id<DQStarButtonDelegate> delegate;
@property (nonatomic, copy) NSString *commentID;
@property (nonatomic, copy) NSDictionary *eventLoggingParameters;
@property (nonatomic, assign) DQStarState starState;

// use this for iPhone - uses standard iPhone star images, sets tintColor to dq_phoneButtonOffColor
// instrinsicContentSize is the size of those standard images
- (id)init;

// use this for iPad - doesn't use tintColor, uses images as-is, uses this size
// instrinsicContentSize is the size specified


- (id)initWithNotStarredImage:(UIImage *)notStarredImage starredImage:(UIImage *)starredImage size:(CGSize)size;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithNotStarredImage:starredImage:size:);
- (id)initWithCoder:(NSCoder *)aDecoder MSDesignatedInitializer(initWithNotStarredImage:starredImage:size:);

- (void)prepareForReuse;

- (void)star;

@end
