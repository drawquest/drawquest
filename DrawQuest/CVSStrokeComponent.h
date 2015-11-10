//
//  CVSStrokeComponent.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/4/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum {
    CVSStrokeComponentTypePoint,
    CVSStrokeComponentTypeCurve
} CVSStrokeComponentType;

@interface CVSStrokeComponent : NSManagedObject

@property (nonatomic, strong) NSNumber *typeNumber;
@property (nonatomic, strong) NSString *fromPointString;
@property (nonatomic, strong) NSString *toPointString;
@property (nonatomic, strong) NSString *controlPoint1String;
@property (nonatomic, strong) NSString *controlPoint2String;

@property (nonatomic) CVSStrokeComponentType type;
@property (nonatomic) CGPoint toPoint;
@property (nonatomic) CGPoint fromPoint;
@property (nonatomic) CGPoint controlPoint1;
@property (nonatomic) CGPoint controlPoint2;
@property (nonatomic, strong) NSManagedObject *stroke;

- (NSDictionary *)componentRepresentation;

@end
