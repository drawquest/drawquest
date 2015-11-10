//
//  CVSColorPickerViewController.m
//  DrawQuest
//
//  Created by David Mauro on 9/13/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSColorPickerViewController.h"

// Views
#import "CVSColorPickerViewCell.h"
#import "DQButton.h"

// Additions
#import "UIImage+DQAdditions.h"
#import "UIColor+DQAdditions.h"
#import "NSDictionary+DQAPIConveniences.h"
#import "CVSUniqueUIColorCache.h"
#import "UIView+STAdditions.h"
#import "UIFont+DQAdditions.h"

static const CGFloat kCVSColorPickerColorWellDiameter = 33.0f;
static NSString *kCVSColorPickerCellIdentifier = @"drawquest.ColorCellIdentifier";

@interface CVSColorPickerBackgroundView : UIView

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, weak) UIView *sourceView;

@end

@interface CVSColorPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, copy) NSArray *colors;
@property (nonatomic, copy) UIColor *selectedColor;
@property (nonatomic, copy) NSArray *portraitLayoutConstraints;
@property (nonatomic, copy) NSArray *landscapeLayoutConstraints;
@property (nonatomic, weak) UICollectionView *colorsGridView;
@property (nonatomic, weak) id<CVSColorPickerViewControllerDelegate> delegate;
@property (nonatomic, weak) CVSColorPickerBackgroundView *backgroundView;
@property (nonatomic, strong) CVSUniqueUIColorCache * uniqueUIColorCache;

@end

@implementation CVSColorPickerViewController

- (id)initWithDelegate:(id<CVSColorPickerViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _delegate = delegate;
        [self updateOwnedColors];
        _selectedColor = [_colors count] ? _colors[0] : nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *dimmerView = [[UIView alloc] initWithFrame:CGRectZero];
    dimmerView.translatesAutoresizingMaskIntoConstraints = NO;
    dimmerView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3f];
    UITapGestureRecognizer *dimmerViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dimmerViewTapped:)];
    [dimmerView addGestureRecognizer:dimmerViewTapRecognizer];
    [self.view addSubview:dimmerView];
    
    CVSColorPickerBackgroundView *backgroundView = [[CVSColorPickerBackgroundView alloc] initWithFrame:CGRectZero];
    backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    backgroundView.sourceView = [self.delegate sourceViewForCVSColorPickerViewController:self];
    [self.view addSubview:backgroundView];
    self.backgroundView = backgroundView;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(kCVSColorPickerColorWellDiameter, kCVSColorPickerColorWellDiameter);
    CGFloat padding = 27.0f;
    flowLayout.minimumInteritemSpacing = 15.0f;
    flowLayout.minimumLineSpacing = 27.0f;
    flowLayout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
    UICollectionView *colorsGridView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    colorsGridView.translatesAutoresizingMaskIntoConstraints = NO;
    colorsGridView.backgroundColor = [UIColor clearColor];
    colorsGridView.delegate = self;
    colorsGridView.dataSource = self;
    [colorsGridView registerClass:[CVSColorPickerViewCell class] forCellWithReuseIdentifier:kCVSColorPickerCellIdentifier];
    [backgroundView.contentView addSubview:colorsGridView];
    self.colorsGridView = colorsGridView;

    UIView *dividerView = [[UIView alloc] initWithFrame:CGRectZero];
    dividerView.translatesAutoresizingMaskIntoConstraints = NO;
    dividerView.backgroundColor = [UIColor dq_phoneDivider];
    [backgroundView.contentView addSubview:dividerView];

    DQButton *shopButton = [DQButton buttonWithType:UIButtonTypeCustom];
    shopButton.translatesAutoresizingMaskIntoConstraints = NO;
    shopButton.titleLabel.font = [UIFont dq_phoneCTAButtonFont];
    shopButton.layer.cornerRadius = 3.0f;
    shopButton.tintColorForBackground = YES;
    [shopButton setTitle:DQLocalizedString(@"Shop for More Colors!", @"Button title in color picker encouraging users to go to the shop") forState:UIControlStateNormal];
    __weak typeof(self) weakSelf = self;
    shopButton.tappedBlock = ^(DQButton *button) {
        if (weakSelf.shopBlock)
        {
            weakSelf.shopBlock(weakSelf);
        }
    };
    [backgroundView.contentView addSubview:shopButton];
    
    NSDictionary *editorSubviews = NSDictionaryOfVariableBindings(dimmerView, backgroundView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dimmerView]|" options:0 metrics:nil views:editorSubviews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[dimmerView]|" options:0 metrics:nil views:editorSubviews]];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-320-[backgroundView]-340-|" options:0 metrics:nil views:editorSubviews]];
        // iPad doesn't actually use portait constraints
        self.portraitLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-125-[backgroundView]-90-|" options:0 metrics:nil views:editorSubviews];
        self.landscapeLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-125-[backgroundView]-90-|" options:0 metrics:nil views:editorSubviews];
    }
    else
    {
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[backgroundView]-5-|" options:0 metrics:nil views:editorSubviews]];
        self.portraitLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-52-[backgroundView]-52-|" options:0 metrics:nil views:editorSubviews];
        self.landscapeLayoutConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-42-[backgroundView]-52-|" options:0 metrics:nil views:editorSubviews];
    }

    NSDictionary *colorSubviews = NSDictionaryOfVariableBindings(colorsGridView, dividerView, shopButton);
    NSDictionary *metrics = @{@"buttonInset": @(20), @"priority": @(UILayoutPriorityDefaultHigh)};
    [backgroundView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[colorsGridView]|" options:0 metrics:metrics views:colorSubviews]];
    [backgroundView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dividerView]|" options:0 metrics:metrics views:colorSubviews]];
    [backgroundView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-buttonInset@priority-[shopButton]-buttonInset@priority-|" options:0 metrics:metrics views:colorSubviews]];
    [backgroundView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[colorsGridView][dividerView(1@priority)]-buttonInset@priority-[shopButton(30@priority)]-buttonInset@priority-|" options:0 metrics:metrics views:colorSubviews]];

    [self setOrientationBasedConstraints];
}

- (void)didReceiveMemoryWarning
{
    if ([self isViewLoaded] && [self.view window] == nil)
    {
        self.view = nil;
        self.portraitLayoutConstraints = nil;
        self.landscapeLayoutConstraints = nil;
    }
    [super didReceiveMemoryWarning];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self setOrientationBasedConstraints];
    [self.backgroundView setNeedsDisplay];
    [self.backgroundView setNeedsLayout];
}

#pragma mark -

- (void)setOrientationBasedConstraints
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        [self.view removeConstraints:self.portraitLayoutConstraints];
        [self.view addConstraints:self.landscapeLayoutConstraints];
    }
    else
    {
        [self.view removeConstraints:self.landscapeLayoutConstraints];
        [self.view addConstraints:self.portraitLayoutConstraints];
    }
}

- (void)updateOwnedColors
{
    NSArray * userColors = [self.delegate colorsForLoggedInAccountForCVSColorPickerViewController:self];
    _uniqueUIColorCache = [CVSUniqueUIColorCache uniqueUIColorCacheWithDefaultEditorColors];
    if ([userColors count] > 0)
    {
        NSMutableArray *uiColors = [NSMutableArray array];
        [userColors enumerateObjectsUsingBlock:^(NSDictionary *color, NSUInteger idx, BOOL *stop) {
            NSArray *currentRGBInfo = color.dq_colorRGBInfo;
            [uiColors addObject:[UIColor dq_colorWithRGBArray:currentRGBInfo]];
        }];

        self.colors = [_uniqueUIColorCache uniqueArrayWithArray:uiColors];
    }
    else
    {
        self.colors = [_uniqueUIColorCache uniqueArrayWithArray:[CVSUniqueUIColorCache defaultEditorColors]];
    }
    [self.colorsGridView reloadData];
}

#pragma mark - Actions

- (void)dimmerViewTapped:(id)sender
{
    if (self.dismissalBlock)
    {
        self.dismissalBlock(self);
    }
}

#pragma mark - UICollectionViewDelegate Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.colors count];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIColor *color = [self.colors objectAtIndex:indexPath.item];
    self.selectedColor = color;
    [collectionView reloadData];
    if (self.colorSelectedBlock)
    {
        self.colorSelectedBlock(self, color);
    }
}

#pragma mark - UICollectionViewDataSource Methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CVSColorPickerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCVSColorPickerCellIdentifier forIndexPath:indexPath];
    UIColor *color = [self.colors objectAtIndex:indexPath.item];
    [cell setColor:color isSelected:[color isEqual:self.selectedColor]];
    return cell;
}

@end


#pragma mark -
#pragma mark - Background View

@implementation CVSColorPickerBackgroundView

static const CGFloat kCVSColorPickerBackgroundViewShadowBlueRadius = 10.0f;
static const CGFloat kCVSColorPickerBackgroundViewArrowWidth = 16.0f;
static const CGFloat kCVSColorPickerBackgroundViewArroHeight = 8.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setOpaque:NO];
        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_contentView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.contentView.frame = [self getVisualBounds];
}

#pragma mark -

- (CGRect)getVisualBounds
{
    return UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(kCVSColorPickerBackgroundViewShadowBlueRadius, kCVSColorPickerBackgroundViewShadowBlueRadius, kCVSColorPickerBackgroundViewShadowBlueRadius + kCVSColorPickerBackgroundViewArroHeight, kCVSColorPickerBackgroundViewShadowBlueRadius));
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return CGRectContainsPoint([self getVisualBounds], point);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIColor *shadow = [[UIColor blackColor] colorWithAlphaComponent: 0.35];
    CGFloat cornerRadius = 10.0f;
    CGPoint pointToPosition = [self convertPoint:self.sourceView.center fromView:self.sourceView.superview];
    
    CGRect bounds = [self getVisualBounds];
    
    CGFloat topEdge = CGRectGetMinY(bounds);
    CGFloat rightEdge = CGRectGetMaxX(bounds);
    CGFloat bottomEdge = CGRectGetMaxY(bounds);
    CGFloat leftEdge = CGRectGetMinX(bounds);
    CGPoint topLeft = CGPointMake(leftEdge, topEdge);
    CGPoint topRight = CGPointMake(rightEdge, topEdge);
    CGPoint bottomLeft = CGPointMake(leftEdge, bottomEdge);
    CGPoint bottomRight = CGPointMake(rightEdge, bottomEdge);
    
    //// Bezier Drawing start from bottom right corner
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(rightEdge, bottomEdge - cornerRadius)];
    [bezierPath addCurveToPoint:CGPointMake(rightEdge - cornerRadius, bottomEdge) controlPoint1:bottomRight controlPoint2:bottomRight];
    // Down arrow
    [bezierPath addLineToPoint:CGPointMake(pointToPosition.x + kCVSColorPickerBackgroundViewArrowWidth/2, bottomEdge)];
    [bezierPath addLineToPoint:CGPointMake(pointToPosition.x, bottomEdge + kCVSColorPickerBackgroundViewArroHeight)];
    [bezierPath addLineToPoint:CGPointMake(pointToPosition.x - kCVSColorPickerBackgroundViewArrowWidth/2, bottomEdge)];
    
    [bezierPath addLineToPoint:CGPointMake(leftEdge + cornerRadius, bottomEdge)];
    [bezierPath addCurveToPoint:CGPointMake(leftEdge, bottomEdge - cornerRadius) controlPoint1:bottomLeft controlPoint2:bottomLeft];
    [bezierPath addLineToPoint:CGPointMake(leftEdge, topEdge + cornerRadius)];
    [bezierPath addCurveToPoint:CGPointMake(leftEdge + cornerRadius, topEdge) controlPoint1:topLeft controlPoint2:topLeft];
    [bezierPath addLineToPoint:CGPointMake(rightEdge - cornerRadius, topEdge)];
    [bezierPath addCurveToPoint:CGPointMake(rightEdge, topEdge + cornerRadius) controlPoint1:topRight controlPoint2:topRight];
    [bezierPath addLineToPoint:CGPointMake(rightEdge, bottomEdge - cornerRadius)];
    [bezierPath closePath];
    
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeZero, kCVSColorPickerBackgroundViewShadowBlueRadius, shadow.CGColor);
    [[UIColor whiteColor] setFill];
    [bezierPath fill];
    CGContextRestoreGState(context);
}

@end
