//
//  CVSStrokeArray.m
//  DrawQuest
//
//  Created by Justin Carlson on 10/14/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSStrokeArray.h"

#import "CVSStroke.h"
#import "CVSStrokeRenderer.h"
#import "DQPapertrailLogger.h"

@interface CVSStrokeArray ()

@property (nonatomic, readonly) NSMutableArray * mstrokes;

@end

@implementation CVSStrokeArray

- (id)init
{
    self = [super init];
    if (nil == self) {
        return nil;
    }
    _mstrokes = [NSMutableArray new];
    return self;
}

+ (instancetype)newStrokeArrayWithStroke:(CVSStroke *)pStroke
{
    assert(pStroke);
    CVSStrokeArray * const result = [CVSStrokeArray new];
    assert(result);
    [result addStroke:pStroke];
    return result;
}

#pragma mark - <NSObject>

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ = {%@}", [super description], self.mstrokes];
}

#pragma mark - <NSMutableCopying>

- (id)mutableCopyWithZone:(NSZone *)zone
{
    CVSStrokeArray * result = [[[self class] allocWithZone:zone] init];
    [result.mstrokes setArray:self.mstrokes];
    return result;
}

#pragma mark - <NSFastEnumeration>

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    return [self.mstrokes countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Interface

- (NSArray *)strokes
{
    return self.mstrokes.copy;
}

- (NSUInteger)count
{
    return self.mstrokes.count;
}

- (void)addStroke:(CVSStroke *)pStroke
{
    if (pStroke)
    {
        if ([pStroke.components count])
        {
            [self.mstrokes addObject:pStroke];
        }
        else
        {
            [DQPapertrailLogger component:@"stroke-array" category:@"add-stroke-bad-stroke" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                return @{@"brush": pStroke.brushTypeNumber ?: [NSNull null]};
            }];
        }
    }
    else
    {
        [DQPapertrailLogger component:@"stroke-array" category:@"add-stroke-nil-stroke" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{};
        }];
    }
}

- (void)addStrokes:(CVSStrokeArray *)pStrokes
{
    [self addStrokesFromArray:pStrokes.mstrokes];
}

- (void)addStrokesFromArray:(NSArray *)pStrokes
{
    if (pStrokes)
    {
        NSIndexSet *indexes = [pStrokes indexesOfObjectsPassingTest:^BOOL(CVSStroke *stroke, NSUInteger idx, BOOL *stop) {
            if ([stroke.components count])
            {
                return YES;
            }
            else
            {
                [DQPapertrailLogger component:@"stroke-array" category:@"add-strokes-from-array-bad-stroke" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"brush": stroke.brushTypeNumber ?: [NSNull null],
                             @"index": @(idx)};
                }];
                return NO;
            }
        }];
        if ([indexes count] == [pStrokes count])
        {
            [self.mstrokes addObjectsFromArray:pStrokes];
        }
        else
        {
            NSArray *goodStrokes = [pStrokes objectsAtIndexes:indexes];
            if ([goodStrokes count])
            {
                [self.mstrokes addObjectsFromArray:goodStrokes];
            }
        }
    }
    else
    {
        [DQPapertrailLogger component:@"stroke-array" category:@"add-strokes-from-array-nil-argument" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{};
        }];
    }
}

- (void)removeStroke:(CVSStroke *)pStroke
{
    assert([self containsStroke:pStroke]);
    [self.mstrokes removeObject:pStroke];
}

- (void)removeAllObjects
{
    @autoreleasepool {
        [self.mstrokes removeAllObjects];
    }
}

- (BOOL)containsStroke:(CVSStroke *)stroke
{
    return [self.strokes containsObject:stroke];
}

- (BOOL)containsStrokeWithBrushType:(CVSBrushType)pBrushType
{
    for (CVSStroke * at in self) {
        if (pBrushType == at.brushType) {
            return YES;
        }
    }
    return NO;
}

- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect
{
    if (0 == self.count) {
        return;
    }
    @autoreleasepool {
        [CVSStrokeRenderer renderStrokes:self clippingRect:pClippingRect context:pContext];
    }
}

- (void)renderInContext:(CGContextRef)pContext clippingRect:(CGRect)pClippingRect useStrokesCGPath:(bool)pUseStrokesCGPath
{
    if (0 == self.count) {
        return;
    }
    @autoreleasepool {
        [CVSStrokeRenderer renderStrokes:self clippingRect:pClippingRect context:pContext useStrokesCGPath:pUseStrokesCGPath];
    }
}

- (CGRect)unionOfStrokesBounds
{
    assert(self.count);
    CGRect rect = CGRectNull;
    for (CVSStroke * at in self.mstrokes) {
        const CGRect bounds = at.bounds;
        if (CGRectIsEmpty(bounds)) {
            assert(0 && "JC: just seeing if this is reachable (it should not be)");
            continue;
        }
        rect = CGRectUnion(rect, bounds);
    }
    return rect;
}

- (CVSMultipleStrokeRenderComplexity)multipleStrokeRenderComplexity
{
    CVSMultipleStrokeRenderComplexity sum = 0;
    for (CVSStroke * at in self.mstrokes) {
        sum += at.singleStrokeRenderComplexity;
    }
    return sum;
}

- (BOOL)isMultipleStrokeRenderComplexityBelow:(CVSMultipleStrokeRenderComplexity)pRenderComplexity
{
    assert(pRenderComplexity);
    return self.multipleStrokeRenderComplexity < pRenderComplexity;
}

- (void)purgeStrokesCachedPaths
{
    for (CVSStroke * at in self.mstrokes) {
        [at purgeCachedPath];
    }
}

- (instancetype)dequeueLastNStrokes:(NSUInteger)pNStrokesToDequeue
{
    CVSStrokeArray * results = [[self class] new];
    NSMutableArray * strokes = self.mstrokes;
    for (size_t i = 0, offset = self.count - pNStrokesToDequeue; i < pNStrokesToDequeue; ++i) {
        [results addStroke:strokes[offset]];
        [strokes removeObjectAtIndex:offset];
    }
    return results;
}

- (instancetype)dequeueAllStrokes
{
    CVSStrokeArray * results = [[self class] new];
    [results.mstrokes setArray:self.mstrokes];
    [self removeAllObjects];
    return results;
}

- (CVSStroke *)dequeueZeroethStroke
{
    const NSUInteger i = 0;
    CVSStroke * stroke = self.mstrokes[i];
    [self.mstrokes removeObjectAtIndex:i];
    return stroke;
}

- (CVSStroke *)dequeueLastStroke
{
    NSMutableArray * strokes = self.mstrokes;
    assert(strokes.count);
    CVSStroke * stroke = strokes.lastObject;
    [strokes removeLastObject];
    return stroke;
}

- (CVSStrokeArray *)dequeueStrokesToFitBelowRenderComplexityThreshold:(CVSMultipleStrokeRenderComplexity)pThreshold
{
    assert(pThreshold);
    assert(self.count);
    CVSStrokeArray * dequeued = [CVSStrokeArray new];
    while (![self isMultipleStrokeRenderComplexityBelow:pThreshold]) {
        [dequeued addStroke:self.dequeueZeroethStroke];
    }
    assert(dequeued.count);
    return dequeued;
}

@end
