//
//  DQPlaybackDataManager.m
//  DrawQuest
//
//  Created by Phillip Bowden on 11/13/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQPlaybackDataManager.h"

// Additions
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"

// Models
#import "CVSDrawing.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "DQComment.h"
#import "DQQuest.h"

// Controllers
#import "DQDataStoreController.h"
#import "DQPublicServiceController.h"
#import "STDataStoreController.h"
#import "STHTTPResourceController.h"

// Views
#import "DQHUDView.h"

@interface DQPlaybackDataManager ()

@property (nonatomic, strong) STHTTPResourceController *imageController;

@end

@implementation DQPlaybackDataManager
{
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    NSManagedObjectContext *_mainContext;
}

- (id)initWithImageController:(STHTTPResourceController *)imageController delegate:(id<DQControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    if (self)
    {
        _imageController = imageController;
        [self reset];
    }
    return self;
}

- (void)reset
{
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Drawings" ofType:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
    [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:NULL];
    _mainContext = [[NSManagedObjectContext alloc] init];
    [_mainContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
}

#pragma mark - Create Managed Objects From JSON

- (CVSDrawing *)drawingForPlaybackData:(NSDictionary *)playbackData
{
    CVSDrawing *drawing = [[CVSDrawing alloc] initWithEntity:[NSEntityDescription entityForName:@"CVSDrawing" inManagedObjectContext:_mainContext] insertIntoManagedObjectContext:_mainContext];
    drawing.usesTemplate = playbackData ? playbackData[@"usesTemplate"] : @NO;
    
    NSArray *strokeRepresentations = playbackData[@"strokes"];
    NSMutableArray *newStrokes = [[NSMutableArray alloc] init];
    [strokeRepresentations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *representation = (NSDictionary *)obj;
        [newStrokes addObject:[self strokeForRepresentation:representation]];
    }];

    drawing.strokes = [NSOrderedSet orderedSetWithArray:newStrokes];
    return drawing;
}

- (CVSStroke *)strokeForRepresentation:(NSDictionary *)dictionary
{
    CVSStroke *stroke = [[CVSStroke alloc] initWithEntity:[NSEntityDescription entityForName:@"CVSStroke" inManagedObjectContext:_mainContext] insertIntoManagedObjectContext:_mainContext];
    stroke.strokeColor = DQColorFromDictionary(dictionary[@"strokeColor"]);
    stroke.brushTypeNumber = dictionary[@"brushType"];
    
    NSArray *componentRepresentations = dictionary[@"components"];
    NSMutableArray *newComponents = [[NSMutableArray alloc] init];
    [componentRepresentations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *representation = (NSDictionary *)obj;
        [newComponents addObject:[self strokeComponentForRepresentation:representation]];
    }];
    
    stroke.components = [NSOrderedSet orderedSetWithArray:newComponents];
    
    return stroke;
}

- (CVSStrokeComponent *)strokeComponentForRepresentation:(NSDictionary *)dictionary
{
    CVSStrokeComponent *strokeComponent = [[CVSStrokeComponent alloc] initWithEntity:[NSEntityDescription entityForName:@"CVSStrokeComponent" inManagedObjectContext:_mainContext] insertIntoManagedObjectContext:_mainContext];
    
    strokeComponent.typeNumber = dictionary[@"type"];
    strokeComponent.fromPointString = dictionary[@"fromPoint"];
    strokeComponent.toPointString = dictionary[@"toPoint"];
    
    if(strokeComponent.type == CVSStrokeComponentTypeCurve) {
        strokeComponent.controlPoint1String = dictionary[@"controlPoint1"];
        strokeComponent.controlPoint2String = dictionary[@"controlPoint2"];
    }
    
    return strokeComponent;
}

- (void)requestDrawingAndTemplateImageForComment:(DQComment *)comment inQuest:(DQQuest *)quest fromViewController:(UIViewController *)presentingViewController resultBlock:(void (^)(CVSDrawing *drawing, UIImage *templateImage))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    DQHUDView *hud = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? [[DQHUDView alloc] initWithFrame:presentingViewController.view.bounds] : nil;
    if (hud)
    {
        [hud showInView:presentingViewController.view animated:YES];
        hud.text = DQLocalizedString(@"Preparing Playback", @"Playback data is being loaded indicator label");
    }

    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestPlaybackDataForCommentID:comment.serverID withCompletionBlock:^(DQHTTPRequest *request, id JSONObject) {
        if (request && JSONObject)
        {
            CVSDrawing *drawing = [weakSelf drawingForPlaybackData:JSONObject];
            [weakSelf requestTemplateImageForDrawing:(CVSDrawing *)drawing fromQuest:quest resultBlock:^(UIImage *image) {
                [hud hideAnimated:YES];
                if (resultBlock)
                {
                    resultBlock(drawing, image);
                }
            } failureBlock:^(NSError *error) {
                [hud hideAnimated:YES];
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }];
        }
        else
        {
            [hud hideAnimated:YES];
            if (failureBlock)
            {
                // FIXME: create a proper error
                failureBlock([NSError errorWithDomain:@"foo" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Unable to playback drawing"}]);
            }
        }
    }];
}

- (void)requestTemplateImageForDrawing:(CVSDrawing *)drawing fromQuest:(DQQuest *)quest resultBlock:(void (^)(UIImage *image))resultBlock failureBlock:(void (^)(NSError *error))failureBlock
{
    if (drawing.usesTemplate)
    {
        NSString *templateURL = [quest imageURLForKey:DQImageKeyQuestTemplate];
        [self.imageController requestImageForURL:templateURL forceReload:NO completionBlock:^(UIImage *image, STHTTPResourceControllerLoadStatus loadStatus, NSError *error) {
            if (error)
            {
                if (failureBlock)
                {
                    failureBlock(error);
                }
            }
            else if (resultBlock)
            {
                resultBlock(image);
            }
        }];
    }
    else if (resultBlock)
    {
        resultBlock(nil);
    }
}

- (void)requestLogPlaybackForComment:(DQComment *)comment withCompletionBlock:(void (^)(DQComment *))completionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.publicServiceController requestLogPlaybackForCommentID:comment.serverID withCompletionBlock:^(DQHTTPRequest *request) {
        if (request.error)
        {
            NSDictionary *userInfo = @{DQCommentObjectNotificationKey: comment};
            [[NSNotificationCenter defaultCenter] postNotificationName:DQCommentPlayedNotification object:nil userInfo:userInfo];
        }
        else
        {
            NSDictionary *responseDictionary = request.dq_responseDictionary;
            [weakSelf.dataStoreController createOrUpdateCommentsFromJSONList:responseDictionary.dq_comments inBackground:YES resultsBlock:^(NSArray *objects) {
                DQComment *comment = [objects firstObject];
                NSDictionary *userInfo = @{DQCommentObjectNotificationKey: comment};
                [[NSNotificationCenter defaultCenter] postNotificationName:DQCommentPlayedNotification object:nil userInfo:userInfo];
                if (completionBlock)
                {
                    completionBlock(comment);
                }
            }];
        }
    }];
}
@end
