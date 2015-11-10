//
//  CVSEditorViewController.m
//  Editor
//
//  Created by Phillip Bowden on 8/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSEditorViewController.h"
#import "CVSPadEditorViewController.h"
#import "CVSPhoneEditorViewController.h"

#import "DQAnalyticsConstants.h"
#import "UIColor+DQAdditions.h"

#import "CVSStrokeManager.h"
#import "STHTTPResourceController.h"
#import "DQAlertView.h"
#import "DQHUDView.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "DQAccount.h"
#import "CVSEditor.h"

NSString * const DQApplicationCrashRecoveryAttemptsKey = @"CrashRecoveryAttempts";
NSString * const DQApplicationDrawingCrashProtectionQuestServerIDKey = @"DrawingCrashProtectionQuestServerID";
static const NSUInteger kCVSEditorViewControllerMaxCrashRecoveryAttempts = 3;

NSString * const CVSColorsUpdatedNotification = @"CVSColorsUpdatedNotification";
NSString * const CVSBrushesUpdatedNotication = @"CVSBrushesUpdatedNotication";

typedef NS_ENUM(NSUInteger, CVSEditorViewControllerType) {
    CVSEditorViewControllerTypeComment,
    CVSEditorViewControllerTypeQuest
};

@interface CVSEditorViewController () <CVSStrokeManagerDelegate, CVSColorPickerViewControllerDelegate, CVSBrushPickerViewControllerDelegate>

@property (nonatomic, strong, readwrite) CVSEditor * editor;

@property (nonatomic, weak) STHTTPResourceController *imageController;

@property (nonatomic, assign) BOOL isLoadingStrokeBackup;
@property (nonatomic, copy) NSString *source;

@property (nonatomic, weak) UIButton *undoButton;
@property (nonatomic, weak) UIButton *redoButton;

@property (nonatomic, strong) DQHUDView *hudView;

@property (nonatomic, strong, readwrite) DQHUDView * undoHUDView;
// record the depth to ensure the balance is met
@property (nonatomic, assign, readwrite) NSInteger undoHUDViewDepth;

@property (nonatomic, assign) CVSEditorViewControllerType editorType;

@end

@implementation CVSEditorViewController

@synthesize selectedColor = _selectedColor;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CVSColorsUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CVSBrushesUpdatedNotication object:nil];
}

- (id)initQuestEditorWithDraftPath:(NSString *)draftPath source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self = [[CVSPadEditorViewController alloc] initWithDelegate:delegate];
    }
    else
    {
        self = [[CVSPhoneEditorViewController alloc] initWithDelegate:delegate];
    }
    if (self)
    {
        _editorType = CVSEditorViewControllerTypeQuest;

        _draftPath = [draftPath copy];
        _editor = [[CVSEditor alloc] initWithRootPath:_draftPath strokeManagerDelegate:self];
        _interfaceVisible = YES;
    }
    return self;
}

- (id)initCommentEditorWithQuest:(DQQuest *)quest draftsPath:(NSString *)draftsPath imageController:(STHTTPResourceController *)imageController source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self = [[CVSPadEditorViewController alloc] initWithDelegate:delegate];
    }
    else
    {
        self = [[CVSPhoneEditorViewController alloc] initWithDelegate:delegate];
    }
    if (self)
    {
        _editorType = CVSEditorViewControllerTypeComment;
        
        _quest = quest;
        _imageController = imageController;
        _source = [source copy];
        
        // right now we only support one draft per quest, but by putting our drafts in subdirectories
        // of the pathToDrafts we can more easily support multiple drafts per quest
        // so we might as well do this to save ourselves headaches later should we decide
        // to support multiple drafts per quest.
        
        _draftPath = [[draftsPath stringByAppendingPathComponent:quest.serverID] stringByAppendingPathComponent:@"Draft"];
        _editor = [[CVSEditor alloc] initWithRootPath:_draftPath strokeManagerDelegate:self];
        _interfaceVisible = YES;
    }
    return self;
}

- (NSUInteger)numberOfCrashRecoveryAttempts
{
    // check to see if there is a stored quest ID... if so, then it means the editor closed without calling
    // viewWillDisappear:. In that case, there was a crash and we should increment the number of attempts.
    NSUInteger result = 0;
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSString *interruptedQuestID = [d objectForKey:DQApplicationDrawingCrashProtectionQuestServerIDKey];
    if (interruptedQuestID && [interruptedQuestID isEqualToString:self.quest.serverID])
    {
        NSNumber *recoveryAttempts = [d objectForKey:DQApplicationCrashRecoveryAttemptsKey];
        result = [recoveryAttempts unsignedIntegerValue];
        if (result <= kCVSEditorViewControllerMaxCrashRecoveryAttempts)
        {
            result++;
            [d setObject:@(result) forKey:DQApplicationCrashRecoveryAttemptsKey];
            [d synchronize];
        }
    }
    return result;
}

#pragma mark -
#pragma mark UIViewController

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)loadDrawing
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:self.quest.serverID forKey:DQApplicationDrawingCrashProtectionQuestServerIDKey];
    [d synchronize];
    self.isLoadingStrokeBackup = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [self.editor load];
            self.isLoadingStrokeBackup = NO;
            if (self.placeholderTemplateImage)
            {
                [self.hudView hideAnimated:YES];
                self.hudView = nil;
            }
            [self.editorView drawingDidFinishLoading];
            [d removeObjectForKey:DQApplicationCrashRecoveryAttemptsKey];
            [d synchronize];
        }
    });
}

- (void)showCrashAlert
{
    __weak typeof(self) weakSelf = self;
    DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Keep trying?", @"Alert title when the editor has repeatedly crashed")
                                                    message:DQLocalizedString(@"Sorry, DrawQuest is having trouble loading this drawing. You can delete it or try loading it again.", @"Alert message")
                                                   delegate:nil
                                          cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDelete", nil, nil, @"Delete", @"Delete button for alert view")
                                          otherButtonTitles:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleRetry", nil, nil, @"Retry", @"Retry button for alert view"), nil];
    alert.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
        {
            DQAlertView *alert = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Are you sure?", @"Destructive request alert confirmation title")
                                                            message:DQLocalizedString(@"Really delete your drawing?", @"Alert message")
                                                           delegate:nil
                                                  cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view")
                                                  otherButtonTitles:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDelete", nil, nil, @"Delete", @"Delete button for alert view"), nil];
            alert.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
                if (buttonIndex == [alert cancelButtonIndex])
                {
                    [weakSelf showCrashAlert];
                }
                else
                {
                    [weakSelf deleteCurrentDrawing];
                }
            };
            [alert show];
        }
        else
        {
            [weakSelf loadDrawing];
        }
    };
    [alert show];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    DQHUDView *HUDView = [[DQHUDView alloc] initWithFrame:self.view.bounds];
    HUDView.text = DQLocalizedString(@"Preparing Quest", @"A blocking HUD message while the editor is loading in.");
    self.hudView = HUDView;

    self.isLoadingStrokeBackup = NO;
    NSUInteger numberOfCrashRecoveryAttempts = [self numberOfCrashRecoveryAttempts];
    // the drawing is loaded from backup as long as it hasn't failed too many times
    if (numberOfCrashRecoveryAttempts <= kCVSEditorViewControllerMaxCrashRecoveryAttempts)
    {
        [self loadDrawing];
    }
    else
    {
        [self showCrashAlert];
    }

    // Zooming scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scrollView.backgroundColor = [UIColor grayColor];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.minimumZoomScale = 0.25;
    scrollView.maximumZoomScale = 4.0;
    scrollView.delegate = self;
    for (UIGestureRecognizer *gestureRecognizer in scrollView.gestureRecognizers)
    {
        if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])
        {
            UIPanGestureRecognizer *panGR = (UIPanGestureRecognizer *)gestureRecognizer;
            panGR.minimumNumberOfTouches = 2;
            panGR.maximumNumberOfTouches = 2;
        }
    }
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;

    // Create Color Picker
    __weak typeof(self) weakSelf = self;
    self.colorPicker = [[CVSColorPickerViewController alloc] initWithDelegate:self];
    self.colorPicker.colorSelectedBlock = ^(CVSColorPickerViewController *vc, UIColor *selectedColor) {
        [weakSelf activeColorChanged:selectedColor];
    };
    self.colorPicker.dismissalBlock = ^(CVSColorPickerViewController *vc) {
        [weakSelf hideColorPicker];
    };
    self.colorPicker.shopBlock = ^(CVSColorPickerViewController *vc) {
        if (weakSelf.addColorsBlock)
        {
            weakSelf.addColorsBlock(weakSelf);
        }
    };

    // Show Interface button
    DQButton *showInterfaceButton = [DQButton buttonWithType:UIButtonTypeCustom];
    showInterfaceButton.hidden = YES;
    showInterfaceButton.tappedBlock = ^(DQButton *button) {
        [weakSelf toggleInterfaceHidden:button];
    };
    UIImage *showImage = [UIImage imageNamed:@"button_bottom_nav_show"];
    [showInterfaceButton setImage:showImage forState:UIControlStateNormal];
    showInterfaceButton.frame = CGRectMake(0.0f, 0.0f, showImage.size.width + 10.0f, showImage.size.height + 20.0f);
    [self.view addSubview:showInterfaceButton];
    self.showInterfaceButton = showInterfaceButton;

    [self initBrushPicker];

    [self initToolBar];

    [self initAutolayout];

    // Put the colorPicker view in the navigationController's view so it can overlap the navigationBar.
    self.colorPicker.view.hidden = YES;
    [self.navigationController.view addSubview:self.colorPicker.view];
    self.colorPicker.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *navigationViews = @{@"colorPicker" : self.colorPicker.view};
    [self.navigationController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[colorPicker]|" options:0 metrics:nil views:navigationViews]];
    [self.navigationController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[colorPicker]|" options:0 metrics:nil views:navigationViews]];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // on iPhone this is done in the presentation completion block to fix some issues
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = YES;
    }

    // Editor View
    CVSEditorView *editorView = [[CVSEditorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f)];
    [self.scrollView addSubview:editorView];
    self.scrollView.delaysContentTouches = NO;
    self.editorView = editorView;

    // Shop related listeners
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorsUpdated:) name:CVSColorsUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushesUpdated:) name:CVSBrushesUpdatedNotication object:nil];
}

- (void)initToolBar
{
    __weak typeof(self) weakSelf = self;
    CVSToolbar *toolbar = [[CVSToolbar alloc] initWithSelectedColor:self.colorPicker.selectedColor brushPicker:self.brushPicker];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    toolbar.brushButtonTappedBlock = ^(UIButton *button) {
        [weakSelf.toolbarView setBrushIsActiveWithNoBrushAnimation:YES];
        [weakSelf displayBrushPicker:weakSelf.brushPicker.hidden];
        [weakSelf updateEditorForBrushType:weakSelf.brushPicker.selectedBrush];
    };
    toolbar.eraserButtonTappedBlock = ^(UIButton *button) {
        weakSelf.toolbarView.brushIsActive = NO;
        [weakSelf updateEditorForBrushType:CVSBrushTypeEraser];
    };
    toolbar.colorButtonTappedBlock = ^(UIButton *button) {
        [weakSelf displayColorPicker];
    };
    toolbar.trashButtonTappedBlock = ^(UIButton *button) {
        [weakSelf trashButtonPressed:button];
    };
    toolbar.undoButtonTappedBlock = ^(UIButton *button) {
        [weakSelf undoPressed:button];
    };
    toolbar.redoButtonTappedBlock = ^(UIButton *button) {
        [weakSelf redoPressed:button];
    };
    toolbar.hideButtonTappedBlock = ^(UIButton *button) {
        [weakSelf toggleInterfaceHidden:button];
    };
    toolbar.disabledToolbarTappedBlock = ^(CVSToolbar *toolbar) {
        [weakSelf displayBrushPicker:NO];
    };
    [self.view addSubview:toolbar];
    self.toolbarView = toolbar;
}

- (void)initAutolayout
{
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self logEvent:DQAnalyticsEventViewEditor withParameters:[self viewEventLoggingParameters]];

    // The interface will shift a bit after viewDidAppear due to
    // DQTabBar changes, so this should get called async to fix
    // the button from being misplaced.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self layoutShowInterfaceButton];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:DQApplicationDrawingCrashProtectionQuestServerIDKey];
    [d removeObjectForKey:DQApplicationCrashRecoveryAttemptsKey];
    [d synchronize];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:CVSColorsUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:CVSBrushesUpdatedNotication object:nil];
        self.colorPicker = nil;
        self.view = nil;
    }
    [super didReceiveMemoryWarning];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.hudView.frame = self.view.bounds;
}

- (NSDictionary *)viewEventLoggingParameters
{
    return @{@"source": self.source ?: @"unknown", @"quest_id": self.quest.serverID ?: @"unknown"};
}

#pragma mark - Actions

- (void)colorsUpdated:(NSNotification *)notification
{
    [self.colorPicker updateOwnedColors];
}

- (void)brushesUpdated:(NSNotification *)notification
{
    [self.brushPicker updateOwnedBrushes];
}

#pragma mark - Interface

- (void)layoutShowInterfaceButton
{
    CGPoint hideButtonPoint = [self.view convertPoint:[self.toolbarView hideButtonCenter] fromView:self.toolbarView];
    CGFloat positionX = hideButtonPoint.x;
    CGFloat positionY = hideButtonPoint.y;
    if (self.toolbarView.isStowed)
    {
        positionY -= [self toolbarHeight];
    }
    else if ( ! self.toolbarView.isEnabled)
    {
        positionY -= [self toolbarEnabledHeightDifference];
    }
    self.showInterfaceButton.center = CGPointMake(positionX, positionY);

    // We keep the button hidden until it's correctly placed.
    self.showInterfaceButton.hidden = NO;
}

#pragma mark - Color Picker

- (void)displayColorPicker
{
    UIView *colorPicker = self.colorPicker.view;
    colorPicker.hidden = NO;
    [colorPicker.superview bringSubviewToFront:colorPicker];
}

- (void)hideColorPicker
{
    self.colorPicker.view.hidden = YES;
}

- (UIColor *)selectedColor
{
    return self.colorPicker.selectedColor;
}

- (void)activeColorChanged:(UIColor *)selectedColor
{
    [self.toolbarView setSelectedColor:selectedColor];
    [self hideColorPicker];
    self.brushPicker.activeColor = selectedColor;
    [self.editor setStrokeColor:selectedColor];
}

#pragma mark - CVSColorPickerViewControllerDelegate Methods

- (UIView *)sourceViewForCVSColorPickerViewController:(CVSColorPickerViewController *)vc
{
    return self.toolbarView.colorButton;
}

- (NSArray *)colorsForLoggedInAccountForCVSColorPickerViewController:(CVSColorPickerViewController *)vc
{
    return self.loggedInAccount.colors;
}

#pragma mark - Brushes

- (void)updateEditorForBrushType:(CVSBrushType)inBrushType
{
    UIColor * color = nil;
    if (inBrushType == CVSBrushTypeEraser) {
        color = [UIColor clearColor];
    }
    else {
        color = self.selectedColor;
    }
    [self.editor updateEditorForBrushType:inBrushType strokeGeneratorColor:color];
}

#pragma mark - Brush Picker

- (void)initBrushPicker
{
    // Create Brush Picker
    self.brushPicker = [[CVSBrushPickerViewController alloc] initWithDelegate:self];
    self.brushPicker.activeColor = self.colorPicker.selectedColor;
    [self addChildViewController:self.brushPicker];
    __weak typeof(self) weakSelf = self;
    self.brushPicker.brushSelectedBlock = ^(CVSBrushPickerViewController *vc, CVSBrushType brushType) {
        weakSelf.toolbarView.brushIsActive = YES;
        [weakSelf displayBrushPicker:NO];
        [weakSelf.toolbarView setSelectedBrushType:brushType];
        [weakSelf updateEditorForBrushType:brushType];
    };
    self.brushPicker.lockedBrushTappedBlock = ^(CVSBrushPickerViewController *vc, CVSBrushType brushType) {
        if (weakSelf.addBrushesBlock)
        {
            weakSelf.addBrushesBlock(weakSelf);
        }
    };

    [self updateEditorForBrushType:self.brushPicker.selectedBrush];
}

- (void)displayBrushPicker:(BOOL)display
{
    [self.brushPicker setHidden:!display withDuration:0.2f];
    [self.toolbarView setEnabled:!display withDuration:0.2f];
    self.hudView.frame = self.view.bounds;
    self.undoHUDView.frame = self.undoHUDView.superview.frame;
}

#pragma mark -
#pragma mark Accessors

- (UIImage *)imageRepresentation
{
    return [self.editorView imageRepresentation];
}

- (CVSDMImageSnapshotQueue *)imageSnapshotQueue
{
    CVSDMImageSnapshotQueue * const result = self.editor.imageSnapshotQueue;
    assert(result);
    return result;
}

- (void)setEditorView:(CVSEditorView *)pEditorView
{
    [self view]; // ensure view is loaded and viewDidLoad has been called
    if (pEditorView != _editorView)
    {
        pEditorView.delegate = self;
        pEditorView.strokeRecorder = self.editor.strokeRecorder;
        pEditorView.templateImage = self.placeholderTemplateImage;

        _editorView = pEditorView;
        self.editor.renderer = pEditorView;

        if (self.editorType == CVSEditorViewControllerTypeComment)
        {
            
            NSString *imageURL = [self.quest imageURLForKey:DQImageKeyQuestTemplate];
            if (imageURL)
            {
                if ((!self.placeholderTemplateImage) || self.isLoadingStrokeBackup)
                {
                    [self.hudView showInView:self.view animated:YES];
                }
                [self.imageController requestImageForURL:imageURL forceReload:NO completionBlock:^(UIImage *image, STHTTPResourceControllerLoadStatus loadStatus, NSError *error) {
                    if (!self.isLoadingStrokeBackup)
                    {
                        [self.hudView hideAnimated:YES];
                        self.hudView = nil;
                    }

                    if (image)
                    {
                        self.editorView.templateImage = image;
                    }
                    else if (!self.placeholderTemplateImage)
                    {
                        UIAlertView *templateLoadAlert = [[UIAlertView alloc] initWithTitle:DQLocalizedString(@"Background Image Failure", @"Editor template failed to download error title") message:DQLocalizedString(@"Unable to load the quest background image. You can still post but it will be missing from your drawing. Exit and re-enter the editor to try again.", @"Editor template failed to download error body") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleDismiss", nil, nil, @"Dismiss", @"Dismiss button for alert view") otherButtonTitles:nil];
                        [templateLoadAlert show];
                    }
                }];
            }
        }
        else if (self.editorType == CVSEditorViewControllerTypeQuest)
        {
            [self.hudView hideAnimated:YES];
            self.hudView = nil;
        }
        [self initializeEditorBitmapStore];
    }
}

- (void)setSelectedColor:(UIColor *)selectedColor
{
    _selectedColor = selectedColor;
    
    self.editor.strokeColor = _selectedColor;
}

#pragma mark -

- (void)initializeEditorBitmapStore
{
    assert(self.editorView);
    const CGSize size = self.editorView.frame.size;
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (1.0 >= scale) {
        scale = 1.0;
    }
    else if (2.0 <= scale) {
        scale = 2.0;
    }
    const size_t width = ceil(size.width * scale);
    const size_t height = ceil(size.height * scale);
    [self.editor initializeEditorBitmapStore:width height:height];
    [self.editorView setEditorBitmapStore:self.editor.editorBitmapStore imageSnapshotQueue:self.imageSnapshotQueue];
}

- (BOOL)isDirty
{
    return [self.editor strokeManagerHoldsRecordedStrokes];
}

- (UIImage *)publish
{
    UIImage *imageRepresentation = nil;
    if ([self isDirty])
    {
        imageRepresentation = [self imageRepresentation];
        if (imageRepresentation)
        {
            [self.editor publishImageAndInvalidateStrokeManager:imageRepresentation];
        }
    }
    return imageRepresentation;
}

#pragma mark - Deletion

- (void)deleteCurrentDrawing
{
    [self.editorView clear];
    [self.editor clearCurrentStrokes];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d removeObjectForKey:DQApplicationCrashRecoveryAttemptsKey];
    [d synchronize];
}

- (void)deleteTemplateImage
{
    [self.editor clearTemplateImage];
    [self.editorView clearTemplateImage];
}

#pragma mark - CVSStrokeManagerDelegate

- (void)strokeManagerUpdatedUndoStacks:(CVSStrokeManager *)strokeManager
{
    [self.toolbarView enableUndo:strokeManager.isUndoAvailable];
    [self.toolbarView enableRedo:strokeManager.isRedoAvailable];
    [self.trashButton setEnabled:strokeManager.isUndoAvailable];
}

#pragma mark
#pragma mark - Actions

- (void)disposeOrCommitActiveStroke
{
    [self.editor.strokeRecorder disposeOrCommitActiveStroke];
    [self.editorView disposeActiveStroke];
}

#pragma mark -

- (CGFloat)toolbarHeight
{
    return 0.0f;
}

- (CGFloat)toolbarEnabledHeightDifference
{
    return 0.0f;
}

- (void)setInterfaceVisible:(BOOL)visible
{
    if (visible != self.interfaceVisible)
    {
        _interfaceVisible = visible;
        [self animateInterfaceHidden:visible];
    }
}

- (void)animateInterfaceHidden:(BOOL)visible
{
    [self.navigationController setNavigationBarHidden:!visible animated:YES];

    // Subclasses should hide the toolbar here
}

- (void)toggleInterfaceHidden:(id)sender
{
    [self setInterfaceVisible:!self.isInterfaceVisible];
    self.editorView.interfaceHiddenManually = !self.isInterfaceVisible;
}

- (void)trashButtonPressed:(id)sender
{
    __weak typeof(self) weakSelf = self;
    DQAlertView *alertView = [[DQAlertView alloc] initWithTitle:DQLocalizedString(@"Confirm", @"Alert confirm button title") message:DQLocalizedString(@"Would you really like to delete your artwork?", @"Delete artwork confirmation alert message") delegate:nil cancelButtonTitle:DQLocalizedStringWithDefaultValue(@"AlertViewButtonTitleCancel", nil, nil, @"Cancel", @"Cancel button for alert view") otherButtonTitles:DQLocalizedString(@"Delete", @"Destroy item alert confirmation button title"), nil];
    alertView.dq_completionBlock = ^(DQAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex != [alert cancelButtonIndex])
        {
            [weakSelf deleteCurrentDrawing];
        }
    };
    [alertView show];
}

- (void)undoPressed:(id)sender
{
    [self.editor undoStroke];
}

- (void)redoPressed:(id)sender
{
    [self.editor redoStroke];
}

#pragma mark - CVSEditorViewDelegate Methods

- (void)hideInterfaceForEditorView:(CVSEditorView *)view
{
    [self setInterfaceVisible:NO];
    if ( ! self.editorView.isInterfaceHiddenManually)
    {
        self.showInterfaceButton.hidden = YES;
    }
}

- (void)showInterfaceForEditorView:(CVSEditorView *)view
{
    [self setInterfaceVisible:YES];
    self.showInterfaceButton.hidden = NO;
}

- (BOOL)isPointBeyondThreshold:(CGPoint)point
{
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat zoomScale = self.scrollView.zoomScale;
    CGFloat buffer = 10.0f * zoomScale;
    CGFloat interfaceTopHeight = 0.0f;
    CGFloat interfaceBottomHeight = [self toolbarHeight] + buffer;
    CGFloat screenHeight = 0.0f;
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        interfaceTopHeight = 44.0f + buffer;
        screenHeight = CGRectGetHeight(screenBounds);
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        interfaceTopHeight = 32.0f + buffer;
        screenHeight = CGRectGetWidth(screenBounds);
    }

    CGFloat yPosition = point.y;
    // Convert y point to screen coordinates
    CGFloat zoomedSize = 768.0f * zoomScale;
    CGFloat scrollOffset = self.scrollView.contentOffset.y;
    CGFloat zoomOffset = (screenHeight - zoomedSize)/2;
    CGFloat scrollAdjustment = (zoomOffset < 0) ? scrollOffset + zoomOffset : 0.0f;
    yPosition = yPosition * zoomScale + zoomOffset - scrollAdjustment;

    if (yPosition < interfaceTopHeight || yPosition > screenHeight - interfaceBottomHeight) {
        return YES;
    }
    return NO;
}

#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.editorView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [self disposeOrCommitActiveStroke];
    [self.editorView synchronizeContentZoomScale:scrollView.zoomScale];
    // Don't use this because we're not changing the scaling factor based on zoom right now
    //[self.editorView setContentScaleFactor:scale * [[UIScreen mainScreen] scale]];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self disposeOrCommitActiveStroke];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self disposeOrCommitActiveStroke];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self disposeOrCommitActiveStroke];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self disposeOrCommitActiveStroke];
    // If the entire image fits on screen, center it.
    UIView *subView = [scrollView.subviews objectAtIndex:0];
    CGFloat offsetX = 0.0;
    CGFloat offsetY = 0.0;
    UIEdgeInsets insets = scrollView.contentInset;
    if (scrollView.bounds.size.width > scrollView.contentSize.width)
    {
        offsetX = (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5;
        insets.left = 0;
        insets.right = 0;
    }
    else
    {
        insets.left = 50;
        insets.right = 50;
    }
    if (scrollView.bounds.size.height > scrollView.contentSize.height)
    {
        offsetY = (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5;
        insets.top = 0;
        insets.bottom = 0;
    }
    else
    {
        insets.top = 50 + self.navigationController.navigationBar.bounds.size.height;
        insets.bottom = 50 + self.toolbarView.bounds.size.height;
    }
    scrollView.contentInset = insets;

    if (offsetX || offsetY)
    {
        subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }
}

#pragma mark - CVSBrushPickerViewControllerDelegate Methods

- (NSArray *)ownedBrushesForBrushPickerViewController:(CVSBrushPickerViewController *)vc
{
    NSArray *result = nil;
    if (self.ownedBrushesBlock)
    {
        result = self.ownedBrushesBlock(self);
    }
    return result;
}

- (NSArray *)globalBrushesForBrushPickerViewController:(CVSBrushPickerViewController *)vc
{
    NSArray *result = nil;
    if (self.globalBrushesBlock)
    {
        result = self.globalBrushesBlock(self);
    }
    return result;
}

- (NSUInteger)timeConsumingUndoWillBegin
{
    assert([NSThread isMainThread]);
    assert(0 <= self.undoHUDViewDepth);
    if (0 == self.undoHUDViewDepth) {
        assert(nil == self.undoHUDView);

        UIView * const parent = self.view;
        assert(parent);

        self.undoHUDView = [[DQHUDView alloc] initWithFrame:parent.bounds];
        NSDictionary * const views = NSDictionaryOfVariableBindings(parent);
        [self.undoHUDView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[parent]" options:0 metrics:nil views:views]];
        [self.undoHUDView showInView:parent animated:NO];
    }
    self.undoHUDViewDepth = self.undoHUDViewDepth + 1;
    // printf("BEGIN | undo depth: %i\n", (int)self.undoHUDViewDepth);
    return self.undoHUDViewDepth;
}

- (NSUInteger)timeConsumingUndoDidEnd
{
    assert([NSThread isMainThread]);
    self.undoHUDViewDepth = self.undoHUDViewDepth - 1;
    assert(0 <= self.undoHUDViewDepth);
    if (0 == self.undoHUDViewDepth) {
        [self.undoHUDView hideAnimated:YES];
        self.undoHUDView = nil;
    }
    // printf("END | undo depth: %i\n", (int)self.undoHUDViewDepth);
    return self.undoHUDViewDepth;
}

@end
