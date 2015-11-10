//
//  CVSStrokeGenerator.m
//  Editor
//
//  Created by Phillip Bowden on 8/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <objc/runtime.h>

#import "CVSStrokeGenerator.h"

#import "UIBezierPath+CVSAdditions.h"

#import "CVSGeometry.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "CVSStrokeManager.h"
#import "CVSUniqueUIColorCache.h"
#import "CVSTrackingBrush.h"

static const NSInteger kStrokeGeneratorPointCount = 4;

@interface CVSStrokeGenerator()

@property (strong, nonatomic) CVSTrackingBrush * trackingBrush;
@property (strong, nonatomic) NSMutableArray *trackingComponents;
@property (strong, nonatomic) NSMutableArray *samplePoints;

@end

@implementation CVSStrokeGenerator
{
    CVSUniqueUIColorCache * uniqueUIColorCache;
    CGPoint _cSamplePointsArray[kStrokeGeneratorPointCount];
    struct {
        unsigned int consumerDidStartStrokeWithComponent:1;
        unsigned int consumerDidContinueStrokeWithComponent:1;
        unsigned int consumerDidEndStroke:1;
    } _consumerFlags;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    uniqueUIColorCache = [CVSUniqueUIColorCache uniqueUIColorCacheWithDefaultEditorColors];
    _samplePoints = [[NSMutableArray alloc] init];
    _trackingComponents = [[NSMutableArray alloc] init];

    return self;
}


- (void)clearSamplePointsArray
{
    [self.samplePoints removeAllObjects];
}

#pragma mark -
#pragma mark Accessors

- (void)setConsumer:(id<CVSStrokeGeneratorConsumer>)consumer
{
    _consumer = consumer;
    _consumerFlags.consumerDidStartStrokeWithComponent = (bool)[_consumer respondsToSelector:@selector(strokeGenerator:didStartStrokeWithComponent:)];
    _consumerFlags.consumerDidContinueStrokeWithComponent = (bool)[_consumer respondsToSelector:@selector(strokeGenerator:didContinueStrokeWithComponent:)];
    _consumerFlags.consumerDidEndStroke = (bool)[_consumer respondsToSelector:@selector(strokeGenerator: didEndStroke:)];
}

- (void)addSamplePoint:(CGPoint)point
{
    if([self.samplePoints count] == kStrokeGeneratorPointCount) {
        [self.samplePoints removeObjectAtIndex:0];
    }

    NSValue *value = [NSValue valueWithCGPoint:point];
    [self.samplePoints addObject:value];
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
    if (strokeColor == nil) {
        _strokeColor = nil;
    }
    else {
        _strokeColor = [uniqueUIColorCache uniqueUIColor:strokeColor];
    }
}

#pragma mark

- (void)startStrokeWithTouch:(UITouch *)inTouch
{
    // Prepare state for new stroke
    [self disposeActiveStroke];
    self.trackingBrush = [[CVSTrackingBrush alloc] initWithBrushType:self.brushType];
    [self.trackingBrush beginTracking];

    UIView *touchedView = inTouch.view;
    while (strcmp(class_getName([touchedView class]), "CVSEditorView") != 0 && class_getName([touchedView class]) != nil) {
        touchedView = touchedView.superview;
    }
    CGPoint origin = [inTouch locationInView:touchedView];
    [self addSamplePoint:origin];

    CVSStrokeComponent *component = [self nextStrokeComponent];
    [self.trackingBrush addStrokeComponent:component];

    if(_consumerFlags.consumerDidStartStrokeWithComponent) {
        [self.consumer strokeGenerator:self didStartStrokeWithComponent:component];
    }
}

- (void)addPointWithTouch:(UITouch *)inTouch
{
    if (!self.trackingBrush.isTracking)
    {
        return;
    }
    UIView *touchedView = inTouch.view;
    while (strcmp(class_getName([touchedView class]), "CVSEditorView") != 0 && class_getName([touchedView class]) != nil) {
        touchedView = touchedView.superview;
    }

    CGPoint point = [inTouch locationInView:touchedView];

    [self addSamplePoint:point];
    CVSStrokeComponent *component = [self nextStrokeComponent];
    [self.trackingBrush addStrokeComponent:component];

    if(_consumerFlags.consumerDidContinueStrokeWithComponent) {
        [self.consumer strokeGenerator:self didContinueStrokeWithComponent:component];
    }
}

- (void)endStroke
{
    [self endStrokeSinglePoint:NO];
}

- (void)endStrokeForSinglePoint
{
    [self endStrokeSinglePoint:YES];
}

- (void)endStrokeSinglePoint:(BOOL)singlePoint
{
    if (!self.trackingBrush.isTracking)
    {
        return;
    }
    if (singlePoint) {
        [self.trackingBrush addLineToPoint:self.trackingBrush.currentPoint];

        if (_consumerFlags.consumerDidContinueStrokeWithComponent) {
            CVSStrokeComponent *component = [self nextStrokeComponent];
            [self.consumer strokeGenerator:self didContinueStrokeWithComponent:component];

            CVSStroke *stroke = [self strokeForCurrentState];
            stroke.components = [NSOrderedSet orderedSetWithObject:component];
            [self.consumer strokeGenerator:self didEndStroke:stroke];
        }
    } else {
        if(_consumerFlags.consumerDidEndStroke) {

            CVSStroke *stroke = [self strokeForCurrentState];
            stroke.components = [NSOrderedSet orderedSetWithArray:self.trackingComponents];
            [self.consumer strokeGenerator:self didEndStroke:stroke];
        }
    }
    // Cleanup stroke-specific state
    [self disposeActiveStroke];
}

- (void)disposeOrCommitActiveStroke
{
    // using the number of events -> components to choose whether or not the tracking stroke should be discarded or committed.
    // events on the iPhone 5 are typically 15-20ms apart. so there is a combination of time and tracking area using this approach.
    const NSUInteger MinComponents = 12;
    const NSUInteger nComponents = self.trackingComponents.count;
    if (MinComponents > nComponents) {
        [self disposeActiveStroke];
        return;
    }
    else {
        [self endStroke];
        return;
    }
}

- (void)disposeActiveStroke
{
    [self.trackingBrush endTracking];
    [self clearSamplePointsArray];
    [self.trackingComponents removeAllObjects];
}

#pragma mark - Path Generation

- (CVSStroke *)strokeForCurrentState
{
    CVSStroke *stroke = [self.strokeManager newStroke];
    stroke.strokeColor = self.strokeColor;
    stroke.brushType = self.brushType;

    if(self.brushType == CVSBrushTypeEraser) {
        self.strokeColor = [UIColor clearColor];
    }
    return stroke;
}

- (CVSStrokeComponent *)nextStrokeComponent
{
    if([self.samplePoints count] < kStrokeGeneratorPointCount) {
        CVSStrokeComponent *component = [self.strokeManager newStrokeComponent];

        if([self.samplePoints count] == 1) {
            CGPoint point = [[self.samplePoints lastObject] CGPointValue];
            component.fromPoint = point;
            component.toPoint = point;
        } else {
            CGPoint fromPoint = [[self.samplePoints objectAtIndex:1] CGPointValue];
            CGPoint toPoint = [[self.samplePoints objectAtIndex:0] CGPointValue];
            component.fromPoint = fromPoint;
            component.toPoint = toPoint;
        }

        [self.trackingComponents addObject:component];

        return component;
    }

    CGPoint samplePoint0 = [[self.samplePoints lastObject] CGPointValue];
    CGPoint samplePoint1 = [[self.samplePoints objectAtIndex:2] CGPointValue];
    CGPoint samplePoint2 = [[self.samplePoints objectAtIndex:1] CGPointValue];
    CGPoint samplePoint3 = [[self.samplePoints objectAtIndex:0] CGPointValue];

    // Calculate the midpoint of lines formed by sample points
    CGFloat line1MidpointX = (samplePoint0.x + samplePoint1.x) / 2.0f;
    CGFloat line1MidpointY = (samplePoint0.y + samplePoint1.y) / 2.0f;
    CGFloat line2MidpointX = (samplePoint1.x + samplePoint2.x) / 2.0f;
    CGFloat line2MidpointY = (samplePoint1.y + samplePoint2.y) / 2.0f;
    CGFloat line3MidpointX = (samplePoint2.x + samplePoint3.x) / 2.0f;
    CGFloat line3MidpointY = (samplePoint2.y + samplePoint3.y) / 2.0f;

    CGFloat line1Length = CVSLineDistance(samplePoint0, samplePoint1);
    CGFloat line2Length = CVSLineDistance(samplePoint1, samplePoint2);
    CGFloat line3Length = CVSLineDistance(samplePoint2, samplePoint3);

    // JC: if the sum of lengths is tiny, the coefficients should be 0. however, i have not seen this manifest (error would be control point with a NaN).
    CGFloat coefficient1 = line1Length / (line1Length + line2Length);
    CGFloat coefficient2 = line2Length / (line2Length + line3Length);

    CGFloat xm1 = line1MidpointX + (line2MidpointX - line1MidpointX) * coefficient1;
    CGFloat ym1 = line1MidpointY + (line2MidpointY - line1MidpointY) * coefficient1;
    CGFloat xm2 = line2MidpointX + (line3MidpointX - line2MidpointX) * coefficient2;
    CGFloat ym2 = line2MidpointY + (line3MidpointY - line2MidpointY) * coefficient2;

    CGFloat smoothValue = 0.5f;

    CGFloat controlPoint1x = xm1 + (line2MidpointX - xm1) * smoothValue + samplePoint1.x - xm1;
    CGFloat controlPoint1y = ym1 + (line2MidpointY - ym1) * smoothValue + samplePoint1.y - ym1;
    CGFloat controlPoint2x = xm2 + (line2MidpointX - xm2) * smoothValue + samplePoint2.x - xm2;
    CGFloat controlPoint2y = ym2 + (line2MidpointY - ym2) * smoothValue + samplePoint2.y - ym2;

    CGPoint fromPoint = CGPointMake(samplePoint1.x, samplePoint1.y);
    CGPoint toPoint = CGPointMake(samplePoint2.x, samplePoint2.y);
    CGPoint controlPoint1 = CGPointMake(controlPoint1x, controlPoint1y);
    CGPoint controlPoint2 = CGPointMake(controlPoint2x, controlPoint2y);

    CVSStrokeComponent *component = [self.strokeManager newStrokeComponent];
    component.type = CVSStrokeComponentTypeCurve;
    component.fromPoint = fromPoint;
    component.toPoint = toPoint;
    component.controlPoint1 = controlPoint1;
    component.controlPoint2 = controlPoint2;
    
    [self.trackingComponents addObject:component];
    
    return component;
}

@end
