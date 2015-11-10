//
//  CVSStrokeManager.m
//  Editor
//
//  Created by Phillip Bowden on 8/9/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSStrokeManager.h"

#import "NSFileManager+STAdditions.h"
#import "UIColor+DQAdditions.h"

#import "CVSDrawing.h"
#import "CVSDrawingTypes.h"
#import "CVSStroke.h"
#import "CVSStrokeComponent.h"
#import "CVSStrokeArray.h"
#import "STDataStoreController.h"
#import "CVSUniqueUIColorCache.h"
#import "CVSBackedRenderer.h"
#import "DQPapertrailLogger.h"

NSString * const CVSStrokeManagerDataIdentifier = @"as.canv.drawquest.drawings";

@interface CVSStrokeManager()

@property (nonatomic, readwrite, strong) CVSDrawing *currentDrawing;
@property (nonatomic, strong) STDataStoreController *dataStoreController;
@property (nonatomic, strong) CVSStrokeArray *committedStack;
@property (nonatomic, strong) CVSStrokeArray *redoStack;
@property (nonatomic, readwrite, getter = isUndoAvailable) BOOL undoAvailable;
@property (nonatomic, readwrite, getter = isRedoAvailable) BOOL redoAvailable;

@end

@implementation CVSStrokeManager

- (id)initWithRootPath:(NSString *)rootPath delegate:(id<CVSStrokeManagerDelegate>)delegate
{
    self = [super init];
    if (!self)
    {
        return nil;
    }
    _rootPath = [rootPath copy];
    _delegate = delegate;

    // ensure the rootPath exists - Note: it might already exist and have a persistent store in it!
    NSFileManager *fm = [NSFileManager new];
    [fm recursivelyCreatePath:_rootPath];

    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"Drawings" ofType:@"momd"];
    _dataStoreController = [[STDataStoreController alloc] initWithIdentifier:CVSStrokeManagerDataIdentifier
                                                               rootDirectory:_rootPath
                                                                   modelPath:modelPath];
    _committedStack = [CVSStrokeArray new];
    _redoStack = [CVSStrokeArray new];

    return self;
}

#pragma mark - Accessors

- (NSUInteger)numberOfStrokes
{
    return self.currentDrawing.numberOfStrokes;
}

#pragma mark - Object Vending

- (CVSStroke *)newStroke
{
    NSManagedObjectContext *moc = self.dataStoreController.mainContext;
    return [[CVSStroke alloc] initWithEntity:[NSEntityDescription entityForName:@"CVSStroke" inManagedObjectContext:moc] insertIntoManagedObjectContext:moc];
}

- (CVSStrokeComponent *)newStrokeComponent
{
    NSManagedObjectContext *moc = self.dataStoreController.mainContext;
    return [[CVSStrokeComponent alloc] initWithEntity:[NSEntityDescription entityForName:@"CVSStrokeComponent" inManagedObjectContext:moc] insertIntoManagedObjectContext:moc];
}

#pragma mark -

- (void)removeDraftFiles
{
    NSString *imagePath = [self.rootPath stringByAppendingPathComponent:@"image.png"];
    NSString *playbackDataPath = [self.rootPath stringByAppendingPathComponent:@"playback.json"];
    NSFileManager *fm = [NSFileManager new];
    [fm removeItemAtPath:imagePath error:NULL];
    [fm removeItemAtPath:playbackDataPath error:NULL];
}

- (void)publishWithImageRepresentation:(UIImage *)editorImage
{
    if (self.numberOfStrokes)
    {
        NSString *imagePath = [self.rootPath stringByAppendingPathComponent:@"image.png"];
        NSString *playbackDataPath = [self.rootPath stringByAppendingPathComponent:@"playback.json"];
        if ([UIImagePNGRepresentation(editorImage) writeToFile:imagePath atomically:NO])
        {
            NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
            [imageURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
        [self writePlaybackDataAsJSONToPath:playbackDataPath];
    }
}

- (void)clearTemplateImage
{
    self.currentDrawing.usesTemplate = @(NO);
}

- (void)clearCurrentStrokes
{
    self.currentDrawing = nil;
    [self.dataStoreController deletePersistentStore];
    [self emptyRedoStack];
    [self emptyUndoStack];
    [self removeDraftFiles];
}

#pragma mark - Stroke Processing

- (void)lazyLoadDrawing
{
    if (!self.currentDrawing)
    {
        [self load];
        if (!self.currentDrawing)
        {
            NSManagedObjectContext *moc = self.dataStoreController.mainContext;
            self.currentDrawing = [[CVSDrawing alloc] initWithEntity:[NSEntityDescription entityForName:@"CVSDrawing" inManagedObjectContext:moc] insertIntoManagedObjectContext:moc];
        }
    }
}

- (void)processStroke:(CVSStroke *)inStroke
{
    [self lazyLoadDrawing];
    if ([inStroke.components count])
    {
        // Update the data store
        inStroke.drawing = self.currentDrawing;
        [self.currentDrawing addStrokesObject:inStroke];

        // Update undo stack
        [self.committedStack addStroke:inStroke];
        [self save];
        [self updateUndoRedoAvailability];
        [self notifyStrokeCountChangeObserver];
    }
    else
    {
        [DQPapertrailLogger component:@"stroke-manager" category:@"process-stroke-bad-stroke" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
            return @{@"brush": inStroke.brushTypeNumber ?: [NSNull null]};
        }];
    }
}

#pragma mark - Saving playback data for upload

- (void)writePlaybackDataAsJSONToPath:(NSString *)path
{
    [self.currentDrawing writePlaybackDataAsJSONToPath:path];
}

#pragma mark - Stroke Count Change Observer

- (void)notifyStrokeCountChangeObserver
{
    [self.strokeCountChangeObserver strokeCountDidChange:self.numberOfStrokes commitPendingStrokes:^{[self transferActiveStrokesToCacheView:YES];}];
}

#pragma mark - Renderer

- (void)rendererShouldUndoStrokes:(CVSStrokeArray *)pStrokes
{
    assert(pStrokes.count);
    [self.renderer rendererShouldUndoStrokes:pStrokes];
}

- (void)rendererShouldRedoStrokes:(CVSStrokeArray *)pStrokes
{
    assert(pStrokes.count);
    [self.renderer rendererShouldRedoStrokes:pStrokes];
}

- (void)rendererShouldRenderStrokeComponent:(CVSStrokeComponent *)pComponent strokeGenerator:(CVSStrokeGenerator *)pStrokeGenerator
{
    [self.renderer rendererShouldRenderStrokeComponent:pComponent strokeGenerator:pStrokeGenerator];
}

- (void)rendererShouldFinishRenderingStroke:(CVSStroke *)pStroke strokeGenerator:(CVSStrokeGenerator *)pStrokeGenerator
{
    [self.renderer rendererShouldFinishRenderingStroke:pStroke strokeGenerator:pStrokeGenerator];
}

- (void)transferActiveStrokesToCacheView:(BOOL)pTransferAll
{
    [self.renderer transferActiveStrokesToCacheView:pTransferAll];
}

#pragma mark - Stroke Storage

- (void)save
{
    @autoreleasepool {
        NSError *error = nil;
        if (![self.dataStoreController.mainContext save:&error])
        {
            NSLog(@"CVSStrokeManager save error: %@", error);
        }
    }
}

- (void)load
{
    @autoreleasepool {
        NSManagedObjectContext *moc = self.dataStoreController.mainContext;
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"CVSDrawing" inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setReturnsObjectsAsFaults:NO];
        request.entity = entity;
        // TODO: remove strokes.strokeColor from this list as it's not a relationship - added in 4a2610a57426c7ab9f0bf99b427d1a5be6e0302e
        [request setRelationshipKeyPathsForPrefetching:@[@"strokes", @"strokes.components", @"strokes.strokeColor"]];

        NSError *error = nil;
        NSArray *drawings = [moc executeFetchRequest:request error:&error];
        if ([drawings count])
        {
            CVSDrawing *d = [drawings objectAtIndex:0];
            self.currentDrawing = d;
            // JC: note that CoreData re-duplicates our colors. color deduplication was initially a test for the unique object cache,
            // but the CoreData model will not be around much longer. then color deduplication can be improved.
            // uses of CVSUniqueUIColorCache really should be reviewed once we move from the old model.
            CVSUniqueUIColorCache * uniqueUIColorCache = d.uniqueUIColorCache;
            CVSStrokeArray * strokeArray = [CVSStrokeArray new];

            NSMutableArray *badBrushes = [NSMutableArray new];
            for (CVSStroke *stroke in d.strokes)
            {
                if ([stroke.components count])
                {
                    [stroke deduplicateObjectStateUsingUIColorCache:uniqueUIColorCache];
                    [self.committedStack addStroke:stroke]; // instead of processStroke: which adds the stroke to the drawing
                    [strokeArray addStroke:stroke];
                }
                else
                {
                    [badBrushes addObject:stroke.brushTypeNumber ?: [NSNull null]];
                    [d removeStrokesObject:stroke];
                    [moc deleteObject:stroke];
                    [self save];
                }
            }
            if ([badBrushes count])
            {
                [DQPapertrailLogger component:@"stroke-manager" category:@"load-bad-strokes" dataBlock:^NSDictionary *(DQPapertrailLogger *logger, NSString *component, NSDictionary *componentDict, NSString *category, NSDictionary *categoryDict) {
                    return @{@"brushes": badBrushes ?: [NSNull null]};
                }];
            }
            if (strokeArray.count) {
                [self rendererShouldRedoStrokes:strokeArray];
            }
        }
        [self updateUndoRedoAvailability];
        [self notifyStrokeCountChangeObserver];
    }
}

#pragma mark - Undo/Redo

- (void)undoStroke
{
    CVSStroke *stroke = self.committedStack.dequeueLastStroke;

    // Update undo stack
    [self.redoStack addStroke:stroke];
    [self updateUndoRedoAvailability];

    // Update the data store
    [self.currentDrawing removeStrokesObject:stroke];
    [self save];
    [self notifyStrokeCountChangeObserver];
    [self rendererShouldUndoStrokes:[CVSStrokeArray newStrokeArrayWithStroke:stroke]];
    [self notifyStrokeCountChangeObserver];
}

- (void)redoStroke
{
    CVSStroke *stroke = self.redoStack.dequeueLastStroke;

    // Update undo stack
    [self.committedStack addStroke:stroke];
    [self updateUndoRedoAvailability];

    // Update the data store
    [self.currentDrawing addStrokesObject:stroke];
    [self save];
    [self notifyStrokeCountChangeObserver];
    [self rendererShouldRedoStrokes:[CVSStrokeArray newStrokeArrayWithStroke:stroke]];
    [self notifyStrokeCountChangeObserver];
}

- (void)emptyUndoStack
{
    [self.committedStack removeAllObjects];
    [self updateUndoRedoAvailability];
    [self notifyStrokeCountChangeObserver];
}

- (void)emptyRedoStack
{
    [self.redoStack removeAllObjects];
    [self updateUndoRedoAvailability];
    [self notifyStrokeCountChangeObserver];
}

- (void)updateUndoRedoAvailability
{
    self.undoAvailable = [self.committedStack count] > 0;
    self.redoAvailable = [self.redoStack count] > 0;

    [self.delegate strokeManagerUpdatedUndoStacks:self];
}

#pragma mark -
#pragma mark CVSStrokeGeneratorConsumer

- (void)strokeGenerator:(CVSStrokeGenerator *)generator didStartStrokeWithComponent:(CVSStrokeComponent *)component
{
    if (self.renderer)
    {
        // Blow away the redo stack if it's available
        if (self.redoAvailable)
        {
            [self emptyRedoStack];
        }

        [self rendererShouldRenderStrokeComponent:component strokeGenerator:generator];
    }
}

- (void)strokeGenerator:(CVSStrokeGenerator *)generator didContinueStrokeWithComponent:(CVSStrokeComponent *)component
{
    [self rendererShouldRenderStrokeComponent:component strokeGenerator:generator];
}

- (void)strokeGenerator:(CVSStrokeGenerator *)generator didEndStroke:(CVSStroke *)stroke
{
    [self processStroke:stroke];
    [self rendererShouldFinishRenderingStroke:stroke strokeGenerator:generator];
}

@end
