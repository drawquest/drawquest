//
//  CVSDrawingTypes.c
//  Editor
//
//  Created by Phillip Bowden on 8/16/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "NSDictionary+DQAPIConveniences.h"

#include "CVSDrawingTypes.h"

#pragma mark - CVSBrushType

UIBezierPath * CVSBrushTypeCreateUIBezierPathWithType(const CVSBrushType pBrushType) {
    return CVSBrushAttributesCreateUIBezierPath(CVSBrushAttributesForBrushType(pBrushType));
}

#pragma mark - CVSBrushAttributes

static CVSBrushAttributes kDefaultPenBrushAttributes = {
    .brushType = CVSBrushTypePen,
    .lineWidth = 2.9f,
    .alpha = 1.0f,
    .lineJoin = kCGLineJoinRound,
    .lineCap = kCGLineCapRound
};

static CVSBrushAttributes kDefaultMarkerBrushAttributes = {
    .brushType = CVSBrushTypeMarker,
    .lineWidth = 20.0f,
    .alpha = 1.0f,
    .lineJoin = kCGLineJoinRound,
    .lineCap = kCGLineCapRound
};

static CVSBrushAttributes kDefaultPaintbrushBrushAttributes = {
    .brushType = CVSBrushTypePaintbrush,
    .lineWidth = 20.18f,
    .alpha = 0.38f,
    .lineJoin = kCGLineJoinRound,
    .lineCap = kCGLineCapRound
};

static CVSBrushAttributes kDefaultEraserBrushAttributes = {
    .brushType = CVSBrushTypeEraser,
    .lineWidth = 15.0f,
    .alpha = 1.0f,
    .lineJoin = kCGLineJoinRound,
    .lineCap = kCGLineCapRound
};

static CVSBrushAttributes kDefaultPaintbucketBrushAttributes = {
    .brushType = CVSBrushTypePaintbucket,
    .lineWidth = 5000.00f,
    .alpha = 0.5f,
    .lineJoin = kCGLineJoinRound,
    .lineCap = kCGLineCapSquare
};


CVSBrushAttributes* CVSBrushAttributesReferenceForBrushType(const CVSBrushType pBrushType) {
    switch (pBrushType) {
        case CVSBrushTypePen:
            return &kDefaultPenBrushAttributes;
        case CVSBrushTypeMarker:
            return &kDefaultMarkerBrushAttributes;
        case CVSBrushTypePaintbrush:
            return &kDefaultPaintbrushBrushAttributes;
        case CVSBrushTypeEraser:
            return &kDefaultEraserBrushAttributes;
        case CVSBrushTypePaintbucket:
            return &kDefaultPaintbucketBrushAttributes;
        case CVSBrushType_Undefined:
        case CVSBrushTypeSpraypaint:
        case CVSBrushTypeCrayon:
        case CVSBrushTypeNotFound:
            break;
    }
    // i would normally call this an error, but this is left for compatibility.
    return &kDefaultPenBrushAttributes;
}

CVSBrushAttributes CVSBrushAttributesForBrushType(const CVSBrushType pBrushType) {
    const CVSBrushAttributes* attributes = CVSBrushAttributesReferenceForBrushType(pBrushType);
    assert(attributes);
    return *attributes;
}

void CVSBrushAttributesConfigureUIBezierPath(const CVSBrushAttributes pBrushAttributes, UIBezierPath * pBezierPath) {
    pBezierPath.lineJoinStyle = pBrushAttributes.lineJoin;
    pBezierPath.lineCapStyle = pBrushAttributes.lineCap;
    pBezierPath.lineWidth = pBrushAttributes.lineWidth;
}

UIBezierPath * CVSBrushAttributesCreateUIBezierPath(const CVSBrushAttributes pBrushAttributes) {
    UIBezierPath * bezierPath = [UIBezierPath bezierPath];
    CVSBrushAttributesConfigureUIBezierPath(pBrushAttributes, bezierPath);
    return bezierPath;
}

#pragma mark - Editor and Shop Helpers

CVSBrushType CVSBrushTypeForCanonicalName(NSString *canonicalName) {
    CVSBrushType brushType = CVSBrushTypeNotFound;
    if ([canonicalName isEqualToString:DQAPIValueBrushesMarker])
    {
        brushType = CVSBrushTypeMarker;
    }
    else if ([canonicalName isEqualToString:DQAPIValueBrushesPencil])
    {
        brushType = CVSBrushTypePen;
    }
    else if ([canonicalName isEqualToString:DQAPIValueBrushesPaintbrush])
    {
        brushType = CVSBrushTypePaintbrush;
    }
    else if ([canonicalName isEqualToString:DQAPIValueBrushesEraser])
    {
        brushType = CVSBrushTypeEraser;
    }
    else if ([canonicalName isEqualToString:DQAPIValueBrushesPaintbucket])
    {
        brushType = CVSBrushTypePaintbucket;
    }
    else if ([canonicalName isEqualToString:DQAPIValueBrushesCrayon])
    {
        brushType = CVSBrushTypeCrayon;
    }
    return brushType;
};

#pragma mark - Logging Helpers

NSString * CVSStringForBrushType(const CVSBrushType pBrushType) {
    switch(pBrushType) {
        case CVSBrushTypePen:
            return @"kPenBrushAttributes";
        case CVSBrushTypeMarker:
            return @"kMarkerBrushAttributes";
        case CVSBrushTypePaintbrush:
            return @"kPaintbrushBrushAttributes";
        case CVSBrushTypeEraser:
            return @"kEraserBrushAttributes";
        case CVSBrushTypeSpraypaint:
            return @"kSpraypaintBrushAttributes";
        case CVSBrushTypeCrayon:
            return @"kCrayonBrushAttributes";
        case CVSBrushTypePaintbucket:
            return @"kPaintbucketBrushAttributes";
        case CVSBrushType_Undefined:
        case CVSBrushTypeNotFound:
            break;
    }
    // i would normally call this an error, but this is left for compatibility.
    return @"kDefaultBrushAttributes";
}
