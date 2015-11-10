//
//  CVSStroke.m
//  Editor
//
//  Created by Phillip Bowden on 10/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSStroke.h"

#import "CVSDrawing.h"
#import "CVSStrokeComponent.h"

#import "UIBezierPath+CVSAdditions.h"
#import "UIColor+DQAdditions.h"
#import "CVSUniqueUIColorCache.h"

@implementation CVSStroke
{
    bool hasCalculatedBounds;
}

@dynamic components;
@dynamic brushTypeNumber;
@dynamic strokeColor;
@dynamic drawing;
@synthesize path = _path;
@synthesize bounds = _bounds;

#pragma mark - Lifetime

- (void)dealloc
{
    if (NULL != _path) {
        CGPathRelease(_path), _path = NULL;
    }
}

- (void)invalidateBounds
{
    _bounds = CGRectNull;
}

- (BOOL)hasCalculatedBounds
{
    return hasCalculatedBounds;
}

- (void)private_init_CVSStroke
{
    [self invalidateBounds];
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    [self private_init_CVSStroke];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    [self private_init_CVSStroke];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
    [self invalidateBounds];
}

- (void)prepareForDeletion
{
    [self purgeCachedPath];
}

#pragma mark - Accessors

- (CVSBrushType)brushType
{
    return (CVSBrushType)[self.brushTypeNumber intValue];
}

- (void)setBrushType:(CVSBrushType)brushType
{
    self.brushTypeNumber = @(brushType);
}

- (CGPathRef)path
{
    if (!self.hasPath)
    {
        [self loadPath];
    }
    assert(_path);
    return _path;
}

- (CGRect)bounds
{
    if (!self.hasCalculatedBounds)
    {
        [self loadPath];
    }
    assert(!CGRectIsNull(_bounds));
    return _bounds;
}

- (void)setComponents:(NSOrderedSet *)components
{
    NSString * key = @"components";
    [self willChangeValueForKey:key];
    [self setPrimitiveValue:components forKey:key];
    [self purgeCachedPath];
    _bounds = CGRectNull;
    hasCalculatedBounds = false;
    [self didChangeValueForKey:key];
}

#pragma mark - Path Caching

- (bool)hasPath
{
    return NULL != _path;
}

- (UIBezierPath *)createUIBezierPathRepresentation
{
    // use the existing path, if it exists
    if (self.hasPath) {
        UIBezierPath * p = [UIBezierPath bezierPathWithCGPath:_path];
        CVSBrushAttributesConfigureUIBezierPath(CVSBrushAttributesForBrushType(self.brushType), p);
        return p;
    }
    // otherwise, reconstruct and cache
    UIBezierPath * bezierPath = [UIBezierPath bezierPath];
    CVSBrushAttributesConfigureUIBezierPath(CVSBrushAttributesForBrushType(self.brushType), bezierPath);
    for (CVSStrokeComponent * component in self.components) {
        [bezierPath cvs_addStrokeComponent:component];
    }
    _path = CGPathCreateCopy(bezierPath.CGPath);
    assert(_path);
    if (CGPathIsEmpty(_path)) {
        // this may cause problems for you if you create a stroke with no components
        _bounds = CGRectNull;
        hasCalculatedBounds = true;
    }
    else {
        const CGRect boundingBox = CGPathGetBoundingBox(_path);
        assert(!CGRectIsNull(boundingBox));
        const CGFloat lineWidth = CVSBrushAttributesForBrushType(self.brushType).lineWidth;
        assert(0 < lineWidth);
        const CGFloat brushWidthScaling = 0.5f * lineWidth;
        _bounds = CGRectIntegral(CGRectInset(boundingBox, -brushWidthScaling, -brushWidthScaling));
        hasCalculatedBounds = true;
    }
    assert(self.hasPath);
    return bezierPath;
}

- (void)loadPath
{
    UIBezierPath * unused = self.createUIBezierPathRepresentation;
#pragma unused(unused)
    assert(self.hasPath);
}

- (void)loadPathIfNeeded
{
    if (self.hasPath) {
        return;
    }
    [self loadPath];
    assert(self.hasPath);
}

#pragma mark - Dictionary Representation

- (NSDictionary *)strokeRepresentation
{
    NSMutableArray *componentRepresentations = [[NSMutableArray alloc] init];
    for (CVSStrokeComponent * at in self.components) {
        [componentRepresentations addObject:[at componentRepresentation]];
    }

    NSDictionary *representation = @{
                                     @"components" : componentRepresentations,
                                     @"strokeColor" : DQDictionaryFromColor(self.strokeColor),
                                     @"brushType" : self.brushTypeNumber
                                     };


    return representation;
}

#pragma mark - Rendering Complexity Estimation

- (CVSSingleStrokeRenderComplexity)singleStrokeRenderComplexity
{
    // yes, this is a very naive estimation. tweak if you need to.
    // an obvious addition would be to evaluate area (bounds).
    // self-intersecting paths have also been mentioned by Jim as complex
    const NSInteger n = (NSInteger)self.components.count;
    const NSInteger n10 = n * 10;
    const NSInteger complexity = n10;
    if (0 >= complexity) {
        return 0;
    }
    if (UINT8_MAX <= complexity) {
        return UINT8_MAX;
    }
    return (CVSSingleStrokeRenderComplexity)n;
}

#pragma mark - Deduplication

- (void)deduplicateObjectStateUsingUIColorCache:(CVSUniqueUIColorCache *)colorCache
{
    assert(colorCache);
    UIColor * current = self.strokeColor;
    if (current == nil) {
        return;
    }
    UIColor * unique = [colorCache uniqueUIColor:current];
    if (unique == current) {
        return;
    }
    self.strokeColor = unique;
}

#pragma mark - Purging

- (void)purgeCachedPath
{
    if (NULL != _path) {
        CGPathRelease(_path), _path = NULL;
    }
}

@end
