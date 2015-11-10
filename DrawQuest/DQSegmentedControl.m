//
//  DQSegmentedControl.m
//  DrawQuest
//
//  Created by David Mauro on 9/19/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQSegmentedControl.h"
#import "DQButton.h"
#import "UIView+STAdditions.h"
#import "UIFont+DQAdditions.h"

static const CGFloat kDQSegmentedControlPadding = 10.0f;

@interface DQSegmentedControl ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray *viewOptionButtons;
@property (nonatomic, readwrite, assign) DQSegmentedControlViewOption currentViewOption;
@property (nonatomic, assign) BOOL hasInitialized;

@end

@implementation DQSegmentedControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _currentViewOption = DQSegmentedControlViewOptionNotFound;
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.layer.shadowOpacity = 0.05f;
        self.layer.shadowRadius = 0.0f;
    }
    return self;
}

- (NSInteger)selectedSegmentIndex
{
    return self.segmentedControl.selectedSegmentIndex;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    self.segmentedControl.selectedSegmentIndex = selectedSegmentIndex;
}

#pragma mark - DataSource and Delegate setters

- (void)setDataSource:(id<DQSegmentedControlDataSource>)dataSource
{
    _dataSource = dataSource;

    // View option images
    NSArray *viewOptionButtonImages = @[
                                        [UIImage imageNamed:@"button_gallery_view_grid"],
                                        [UIImage imageNamed:@"button_gallery_view_list"]
                                        ];

    if (self.segmentedControl)
    {
        [self.segmentedControl removeFromSuperview];
    }

    // Setup segmented control
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[dataSource itemsForSegmentedControl:self]];
    self.segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.segmentedControl.selectedSegmentIndex = ([dataSource respondsToSelector:@selector(defaultSegmentIndexForSegmentedControl:)]) ? [dataSource defaultSegmentIndexForSegmentedControl:self] : 0;
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName : [UIFont dq_phoneSegmentedControlFont]} forState:UIControlStateNormal];
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.segmentedControl];

    // Create view option buttons based on DQSegmentedControlViewOptions enum
    if ([dataSource respondsToSelector:@selector(shouldDisplayViewOptionsForSegmentedControl:)] && [dataSource shouldDisplayViewOptionsForSegmentedControl:self])
    {
        __weak typeof(self) weakSelf = self;
        NSMutableArray *buttons = [[NSMutableArray alloc] init];
        for (DQSegmentedControlViewOption index = 0; index < DQSegmentedControlViewOptionCount; index++)
        {
            UIImage *image = [viewOptionButtonImages objectAtIndex:index];
            DQButton *viewOptionButton = [DQButton buttonWithImage:image];
            viewOptionButton.translatesAutoresizingMaskIntoConstraints = NO;
            viewOptionButton.tappedBlock = ^(DQButton *button) {
                [weakSelf setViewOption:index];
            };
            [viewOptionButton setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
            [buttons addObject:viewOptionButton];
            [self addSubview:viewOptionButton];
        }
        self.viewOptionButtons = [NSArray arrayWithArray:buttons];

        // Layout the buttons sorted left to right
        static const CGFloat viewOptionPadding = 10.0f;
        for (NSInteger index = [self.viewOptionButtons count] - 1; index >= 0; index--)
        {
            DQButton *button = [_viewOptionButtons objectAtIndex:index];
            if (index == [self.viewOptionButtons count] - 1)
            {
                // Right-most flush against the right side of the superview
                [self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:button.superview attribute:NSLayoutAttributeRight multiplier:1.0f constant:-kDQSegmentedControlPadding]];
            }
            else
            {
                DQButton *relativeToButton = [self.viewOptionButtons objectAtIndex:index + 1];
                [self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:relativeToButton attribute:NSLayoutAttributeLeft multiplier:1.0f constant:-viewOptionPadding]];
            }
            [self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:button.superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:button.superview attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-kDQSegmentedControlPadding*2]];
        }

        // Layout segmented control with view option buttons
        NSDictionary *viewBindings = @{@"segmentedControl": self.segmentedControl, @"leftMostViewOptionButton": [self.viewOptionButtons objectAtIndex:0]};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-controlPadding-[segmentedControl]-padding-[leftMostViewOptionButton]" options:0 metrics:@{@"controlPadding": @(kDQSegmentedControlPadding), @"padding": @(viewOptionPadding)} views:viewBindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=controlPadding-[segmentedControl(==leftMostViewOptionButton)]->=controlPadding-|" options:0 metrics:@{@"controlPadding": @(kDQSegmentedControlPadding)} views:viewBindings]];

        // Default view option
        if ([dataSource respondsToSelector:@selector(defaultViewOptionForSegmentedControl:)])
        {
            [self setViewOption:[dataSource defaultViewOptionForSegmentedControl:self]];
        }
        else
        {
            [self setViewOption:0];
        }
    }
    else
    {
        // Layout segmented control without view option buttons
        NSDictionary *viewBindings = @{@"segmentedControl": self.segmentedControl};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-controlPadding-[segmentedControl]-controlPadding-|" options:0 metrics:@{@"controlPadding": @(kDQSegmentedControlPadding)} views:viewBindings]];
    }

    // Layout the segmented control regardless of view option buttons
    NSDictionary *viewBindings = @{@"segmentedControl": self.segmentedControl};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=controlPadding-[segmentedControl]->=controlPadding-|" options:0 metrics:@{@"controlPadding": @(kDQSegmentedControlPadding)} views:viewBindings]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.segmentedControl attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.segmentedControl.superview attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
}

#pragma mark - Segment and View Option selection

- (void)setViewOption:(DQSegmentedControlViewOption)viewOption
{
    if (viewOption != self.currentViewOption)
    {
        self.currentViewOption = viewOption;

        for (DQButton *button in self.viewOptionButtons)
        {
            button.selected = NO;
        }
        
        DQButton *activeButton = [self.viewOptionButtons objectAtIndex:viewOption];
        activeButton.selected = YES;
        
        if ([self.delegate respondsToSelector:@selector(segmentedControl:didSelectViewOption:)])
        {
            [self.delegate segmentedControl:self didSelectViewOption:viewOption];
        }
        else
        {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"DQSegmentedControl: view options are available but delegate does not respond to segmentedControl:didSelectViewOption:"
                                         userInfo:nil];
        }
    }
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)segmentedControl
{
    NSUInteger *index = segmentedControl.selectedSegmentIndex;
    [self.delegate segmentedControl:self didSelectSegmentIndex:index];
}

- (void)didMoveToWindow
{
    if ( ! self.hasInitialized)
    {
        self.hasInitialized = YES;
        [self segmentedControlValueChanged:self.segmentedControl];
        [self setViewOption:self.currentViewOption];
    }
}

@end
