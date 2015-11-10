//
//  CVSBrushPickerViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQViewController.h"
#import "CVSDrawingTypes.h"
#import "CVSBrushView.h"
#import "CVSBrushesViewCell.h"

extern const CGFloat kCVSBrushPickerViewControllerDesiredHeight;
extern const CGFloat kCVSBrushPickerViewControllerDesiredOffsetFromBottom;

@class CVSBrushPickerViewController;

@protocol CVSBrushPickerViewControllerDelegate <NSObject>

- (NSArray *)ownedBrushesForBrushPickerViewController:(CVSBrushPickerViewController *)vc;
- (NSArray *)globalBrushesForBrushPickerViewController:(CVSBrushPickerViewController *)vc;

@end

@interface CVSBrushPickerViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIColor *activeColor;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, weak, readonly) UICollectionView *collectionView;
@property (nonatomic, readonly, assign, getter = isHidden) BOOL hidden;
@property (nonatomic, readonly, assign, getter = isStowed) BOOL stowed;
@property (nonatomic, readonly) CVSBrushType selectedBrush;
@property (nonatomic, weak) CVSBrushesViewCell *activeBrushCell;
@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, copy) void(^brushSelectedBlock)(CVSBrushPickerViewController *vc, CVSBrushType brushType);
@property (nonatomic, copy) void(^lockedBrushTappedBlock)(CVSBrushPickerViewController *vc, CVSBrushType brushType);

- (id)initWithDelegate:(id<CVSBrushPickerViewControllerDelegate>)delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil MSDesignatedInitializer(initWithDelegate:);

- (void)setHidden:(BOOL)hidden withDuration:(CGFloat)duration;
- (void)setStowed:(BOOL)stowed withDuration:(CGFloat)duration distance:(CGFloat)distance;

- (void)deselectAll;
- (void)setStowed:(BOOL)stowed;
- (CVSBrushType)brushTypeForIndexPath:(NSIndexPath *)indexPath;

- (void)updateOwnedBrushes;

- (CGFloat)widthOfBrushes;
- (NSInteger)numberOfBrushes;

@end
