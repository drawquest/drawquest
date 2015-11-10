//
//  CVSEditorViewController.h
//  Editor
//
//  Created by Phillip Bowden on 8/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "CVSDrawing.h"
#import "CVSDrawingTypes.h"
#import "CVSEditorView.h"
#import "DQQuest.h"
#import "CVSColorPickerViewController.h"
#import "CVSToolbar.h"
#import "DQButton.h"

#import "CVSBrushPickerViewController.h"

extern NSString * const DQApplicationDrawingCrashProtectionQuestServerIDKey;
extern NSString * const DQApplicationCrashRecoveryAttemptsKey;
extern NSString * const CVSColorsUpdatedNotification;
extern NSString * const CVSBrushesUpdatedNotication;

@class STHTTPResourceController;

@interface CVSEditorViewController : DQViewController <CVSEditorViewDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) CVSEditorView *editorView;

@property (nonatomic, assign) BOOL moreColorsDisabled;

@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, readonly, copy) NSString *draftPath;
@property (nonatomic, assign, getter = isInterfaceVisible) BOOL interfaceVisible;
@property (nonatomic, strong) DQQuest *quest;
@property (nonatomic, strong) UIImage *placeholderTemplateImage;
@property (nonatomic, copy) void (^addColorsBlock)(CVSEditorViewController *c);
@property (nonatomic, copy) void (^addBrushesBlock)(CVSEditorViewController *c);
@property (nonatomic, copy) NSArray *(^ownedBrushesBlock)(CVSEditorViewController *c);
@property (nonatomic, copy) NSArray *(^globalBrushesBlock)(CVSEditorViewController *c);
@property (nonatomic, weak) UIButton *trashButton;

// New UI
@property (nonatomic, strong) CVSColorPickerViewController *colorPicker;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) CVSToolbar *toolbarView;
@property (nonatomic, weak) DQButton *showInterfaceButton;
@property (nonatomic, strong) CVSBrushPickerViewController *brushPicker;

// designated initializers
- (id)initCommentEditorWithQuest:(DQQuest *)quest draftsPath:(NSString *)draftsPath imageController:(STHTTPResourceController *)imageController source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate;
- (id)initQuestEditorWithDraftPath:(NSString *)draftPath source:(NSString *)source delegate:(id<DQViewControllerDelegate>)delegate;

- (id)init MSDesignatedInitializer(initCommentEditorWithQuest:draftsPath:imageController:source:delegate:);

- (void)updateEditorForBrushType:(CVSBrushType)inBrushType;

- (BOOL)isDirty;
- (UIImage *)publish;

- (void)toggleInterfaceHidden:(id)sender;
- (void)trashButtonPressed:(id)sender;
- (void)undoPressed:(id)sender;
- (void)redoPressed:(id)sender;

- (void)disposeOrCommitActiveStroke;

- (void)layoutShowInterfaceButton;
- (void)activeColorChanged:(UIColor *)selectedColor;
- (void)animateInterfaceHidden:(BOOL)visible;
- (void)initAutolayout;

- (CGFloat)toolbarHeight;
- (CGFloat)toolbarEnabledHeightDifference;

@end
