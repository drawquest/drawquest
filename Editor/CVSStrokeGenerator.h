//
//  CVSStrokeGenerator.h
//  Editor
//
//  Created by Phillip Bowden on 8/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

#import "CVSDrawingTypes.h"
#import "CVSStrokeRecorder.h"

@class CVSStroke;
@class CVSStrokeComponent;
@class CVSStrokeManager;
@class UIColor;

@protocol CVSStrokeGeneratorConsumer;

@interface CVSStrokeGenerator : NSObject <CVSStrokeRecorder>

@property (nonatomic, weak) id<CVSStrokeGeneratorConsumer> consumer;
@property (strong, nonatomic) CVSStrokeManager *strokeManager;
@property (nonatomic) CVSBrushType brushType;
@property (strong, nonatomic) UIColor *strokeColor;

/**
 @brief this is used when handling events. the stroke generator determines whether a stroke should be committed or disposed of in the event gestures should be interpreted as zoom events.
 */
- (void)disposeOrCommitActiveStroke;

@end

@protocol CVSStrokeGeneratorConsumer <NSObject>

- (void)strokeGenerator:(CVSStrokeGenerator *)generator didStartStrokeWithComponent:(CVSStrokeComponent *)component;
- (void)strokeGenerator:(CVSStrokeGenerator *)generator didContinueStrokeWithComponent:(CVSStrokeComponent *)component;
- (void)strokeGenerator:(CVSStrokeGenerator *)generator didEndStroke:(CVSStroke *)stroke;


@end
