//
//  CVSDrawingTypes.h
//  Editor
//
//  Created by Phillip Bowden on 8/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIBezierPath;

#pragma mark -
#pragma mark CVSBrushType

// THE ORDER OF THESE CANNOT CHANGE
typedef NS_ENUM(NSUInteger, CVSBrushType) {
    /** @constant do not use */
    CVSBrushType_Undefined = 0,
    /** @constant a narrow solid opaque line */
    CVSBrushTypePen = 1,
    /** @constant a wide solid opaque line */
    CVSBrushTypeMarker,
    /** @constant a wide translucent line */
    CVSBrushTypePaintbrush,
    /** @constant wide stroke which uses a clear function */
    CVSBrushTypeEraser,
    CVSBrushTypeSpraypaint,
    CVSBrushTypeCrayon,
    CVSBrushTypePaintbucket,
    CVSBrushTypeCount = CVSBrushTypePaintbucket,
    CVSBrushTypeNotFound = NSNotFound
};

/**
 @return an empty UIBezierPath configured for the specified brush type.
 */
extern UIBezierPath * CVSBrushTypeCreateUIBezierPathWithType(const CVSBrushType pBrushType);

#pragma mark -
#pragma mark CVSBrushAttributes

typedef struct {
    CVSBrushType brushType;
    CGFloat lineWidth;
    CGFloat alpha;
    CGLineJoin lineJoin;
    CGLineCap lineCap;
} CVSBrushAttributes;

extern CVSBrushAttributes * CVSBrushAttributesReferenceForBrushType(const CVSBrushType pBrushType);
extern CVSBrushAttributes CVSBrushAttributesForBrushType(const CVSBrushType pBrushType);

/**
 @return an empty UIBezierPath configured with the specified brush attributes.
 */
extern UIBezierPath * CVSBrushAttributesCreateUIBezierPath(const CVSBrushAttributes pBrushAttributes);

/**
 @brief applies the brush attributes to the path.
 */
extern void CVSBrushAttributesConfigureUIBezierPath(const CVSBrushAttributes pBrushAttributes, UIBezierPath * pBezierPath);

#pragma mark -
#pragma mark Editor and Shop Helpers

extern CVSBrushType CVSBrushTypeForCanonicalName(NSString *canonicalName);

#pragma mark -
#pragma mark Logging Helpers

extern NSString * CVSStringForBrushType(const CVSBrushType pBrushType);

