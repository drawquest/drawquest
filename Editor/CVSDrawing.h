//
//  CVSDrawing.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/5/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CVSStroke;
@class CVSUniqueUIColorCache;

@interface CVSDrawing : NSManagedObject

@property (nonatomic, strong) NSOrderedSet *strokes;
@property (nonatomic, strong) NSNumber *usesTemplate;

- (CVSUniqueUIColorCache *)uniqueUIColorCache;

- (void)addStrokesObject:(CVSStroke *)stroke;
- (void)removeStrokesObject:(CVSStroke *)stroke;

- (NSUInteger)numberOfStrokes;

- (NSDictionary *)playbackRepresentation;

- (void)writePlaybackDataAsJSONToPath:(NSString *)path;

- (void)deduplicateObjectState;

@end
