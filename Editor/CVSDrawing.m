//
//  CVSDrawing.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/5/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSDrawing.h"
#import "STUtils.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "UIColor+DQAdditions.h"
#import "CVSUniqueUIColorCache.h"

@implementation CVSDrawing
{
    CVSUniqueUIColorCache * uniqueUIColorCache;
}

@dynamic strokes;
@dynamic usesTemplate;

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
    if (self == nil) {
        return nil;
    }
    uniqueUIColorCache = [CVSUniqueUIColorCache uniqueUIColorCacheWithDefaultEditorColors];
    return self;
}

- (CVSUniqueUIColorCache *)uniqueUIColorCache
{
    return uniqueUIColorCache;
}

- (void)writePlaybackDataAsJSONToPath:(NSString *)path
{
    NSFileManager *fm = [NSFileManager new];
    if (![fm recursivelyCreatePath:path lastComponentIsFile:YES])
    {
        NSLog(@"Unable to recursively create path: %@", path);
        return;
    }

    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!handle)
    {
        NSLog(@"Unable to open file handle to write at path: %@.", path);
        return;
    }
    [handle truncateFileAtOffset:0];

    NSData *commaData = [@"," dataUsingEncoding:NSUTF8StringEncoding];
    NSData *postambleData = [@"]}" dataUsingEncoding:NSUTF8StringEncoding];

    // write the preamble of the drawing
    NSString *drawingPreamble = [NSString stringWithFormat:@"{\"usesTemplate\":%@,\"strokes\":[", self.usesTemplate ? @"1" : @"0"];
    [handle writeData:[drawingPreamble dataUsingEncoding:NSUTF8StringEncoding]];

    // keep a cache of the JSON representation of stroke colors
    NSMutableDictionary *colors = [[NSMutableDictionary alloc] init];
    CVSUniqueUIColorCache * colorCache = self.uniqueUIColorCache;
    

    // write the strokes of the drawing
    [self.strokes enumerateObjectsUsingBlock:^(CVSStroke *stroke, NSUInteger idx, BOOL *_) {
        // JSON doesn't allow trailing commas, so only write out a comma before the 2nd or later iterations
        if (idx)
        {
            [handle writeData:commaData];
        }

        // look up the strokeColor's JSON from the cache, creating/caching its JSON if necessary
        // since we currently have a very limited palette, this cache will not become too big
        UIColor * strokeColor = stroke.strokeColor;
        id colorKey = [colorCache uniqueUIColor:strokeColor];
        NSString *colorJSON = [colors objectForKey:colorKey];
        if (!colorJSON)
        {
            NSData *JSONData = [NSJSONSerialization dataWithJSONObject:DQDictionaryFromColor(strokeColor) options:0 error:nil];
            colorJSON = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
            [colors setObject:colorJSON forKey:colorKey];
        }

        // write the preamble of the current stroke
        NSString *strokePreamble = [NSString stringWithFormat:@"{\"brushType\":%d,\"strokeColor\":%@,\"components\":[", [stroke.brushTypeNumber intValue], colorJSON];
        [handle writeData:[strokePreamble dataUsingEncoding:NSUTF8StringEncoding]];

        // write the components for the current stroke
        [stroke.components enumerateObjectsUsingBlock:^(CVSStrokeComponent *comp, NSUInteger idx, BOOL *_) {
            // JSON doesn't allow trailing commas, so only write out a comma before the 2nd or later iterations
            if (idx)
            {
                [handle writeData:commaData];
            }
            // components have a "constant" size so it's safe to use JSONKit's serializer to serialize them directly
            [handle writeData:[NSJSONSerialization dataWithJSONObject:[comp componentRepresentation] options:0 error:nil]];
        }];
        // end the stroke with postamble to close the components array and object
        [handle writeData:postambleData];
    }];

    // end the drawing with postamble to close the strokes array and object
    [handle writeData:postambleData];
    [handle closeFile];
}

- (NSDictionary *)playbackRepresentation
{
    NSMutableArray *strokeRepresentations = [[NSMutableArray alloc] init];
    [self.strokes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CVSStroke *stroke = (CVSStroke *)obj;
        [strokeRepresentations addObject:[stroke strokeRepresentation]];
    }];
    
    NSDictionary *representation = @{
    @"strokes" : strokeRepresentations,
    @"usesTemplate" : self.usesTemplate
    };
    
    
    return representation;
}

- (void)addStrokesObject:(CVSStroke *)stroke
{
    NSMutableOrderedSet *intermediateSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"strokes"]];
    NSUInteger strokeIndex = [intermediateSet count];
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:strokeIndex];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"strokes"];
    [intermediateSet addObject:stroke];
    [self setPrimitiveValue:intermediateSet forKey:@"strokes"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"strokes"];
}

- (void)removeStrokesObject:(CVSStroke *)stroke
{
    NSMutableOrderedSet *intermediateSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self mutableOrderedSetValueForKey:@"strokes"]];
    NSUInteger index = [intermediateSet indexOfObject:stroke];
    if (index != NSNotFound) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"strokes"];
        [intermediateSet removeObject:stroke];
        [self setPrimitiveValue:intermediateSet forKey:@"strokes"];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"strokes"];
    }
}

- (NSUInteger)numberOfStrokes
{
    return self.strokes.count;
}

- (void)deduplicateObjectState
{
    CVSUniqueUIColorCache * cache = self.uniqueUIColorCache;
    for (CVSStroke * stroke in self.strokes) {
        [stroke deduplicateObjectStateUsingUIColorCache:cache];
    }
}

@end
