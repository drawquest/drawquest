//
//  DQQuantifiedSegmentedControl.m
//  DrawQuest
//
//  Created by David Mauro on 10/18/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQQuantifiedSegmentedControl.h"

#import "UIView+STAdditions.h"
#import "UIFont+DQAdditions.h"

#pragma mark -
#pragma mark DQQuantifiedSegment

@interface DQQuantifiedSegment : UIView

@property (nonatomic, strong) UIColor *foregroundColor;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, strong, readonly) UILabel *title;
@property (nonatomic, strong, readonly) UILabel *count;
@property (nonatomic, assign) BOOL selected;

- (id)initWithTitle:(NSString *)title;
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithTitle:);

@end

@implementation DQQuantifiedSegment

- (id)initWithTitle:(NSString *)title
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        _title = [[UILabel alloc] initWithFrame:CGRectZero];
        _title.numberOfLines = 1;
        _title.lineBreakMode = NSLineBreakByTruncatingTail;
        _title.textAlignment = NSTextAlignmentCenter;
        _title.font = [UIFont dq_segmentControlTitle];
        [self addSubview:_title];

        _count = [[UILabel alloc] initWithFrame:CGRectZero];
        _count.numberOfLines = 1;
        _count.lineBreakMode = NSLineBreakByTruncatingTail;
        _count.textAlignment = NSTextAlignmentCenter;
        _count.font = [UIFont dq_segmentControlCount];
        [self addSubview:_count];

        _title.text = title;
        _count.text = @"0";
    }
    return self;
}

- (void)setForegroundColor:(UIColor *)foregroundColor
{
    _foregroundColor = foregroundColor;
    [self setNeedsLayout];
}

- (void)setSelected:(BOOL)selected
{
    if (selected != _selected)
    {
        _selected = selected;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.title sizeToFit];
    [self.count sizeToFit];

    CGRect labelsFrame = [self centeredSubRectOfSize:CGSizeMake(self.frameWidth - 10.0f, self.title.frameHeight + self.count.frameHeight)];
    CGRect titleFrame;
    CGRect countFrame;
    CGRectDivide(labelsFrame, &titleFrame, &countFrame, self.title.frameHeight, CGRectMinYEdge);
    self.title.frame = titleFrame;
    self.count.frame = countFrame;

    self.backgroundColor = self.selected ? self.foregroundColor : self.bgColor;
    self.title.textColor = self.selected ? self.bgColor : self.foregroundColor;
    self.count.textColor = self.selected ? self.bgColor : self.foregroundColor;
}

@end

#pragma mark -
#pragma mark DQQuantifiedSegmentedControl

@interface DQQuantifiedSegmentedControl ()

@property (nonatomic, strong) NSArray *segments;
@property (nonatomic, strong) UIView *contentView;

@end

@implementation DQQuantifiedSegmentedControl

- (id)initWithItems:(NSArray *)items
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.layer.shadowOpacity = 0.05f;
        self.layer.shadowRadius = 0.0f;

        _contentView = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = self.tintColor;
        _contentView.layer.borderColor = [self.tintColor CGColor];
        _contentView.layer.borderWidth = 1.0f;
        _contentView.layer.cornerRadius = 5.0f;
        _contentView.clipsToBounds = YES;
        [self addSubview:_contentView];

        NSMutableArray *segments = [[NSMutableArray alloc] init];
        for (NSString *title in items)
        {
            DQQuantifiedSegment *segment = [[DQQuantifiedSegment alloc] initWithTitle:title];
            segment.bgColor = [UIColor whiteColor];
            segment.foregroundColor = self.tintColor;
            segment.translatesAutoresizingMaskIntoConstraints = NO;
            segment.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(segmentTapped:)];
            [segment addGestureRecognizer:tapRecognizer];
            [segments addObject:segment];
            [_contentView addSubview:segment];
        }
        _segments = segments;

        _selectedSegmentIndex = NSNotFound;
    }
    return self;
}

- (void)tintColorDidChange
{
    [super tintColorDidChange];

    self.contentView.backgroundColor = self.tintColor;
    self.contentView.layer.borderColor = [self.tintColor CGColor];
    for (DQQuantifiedSegment *segment in self.segments)
    {
        segment.foregroundColor = self.tintColor;
    }
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, 10.0f, 10.0f);
    self.contentView.frame = bounds;

    bounds = self.contentView.bounds;
    CGFloat dividerWidth = 1.0f;
    NSUInteger count = [self.segments count];
    CGFloat segmentWidth = (bounds.size.width - dividerWidth * count)/count;
    for (DQQuantifiedSegment *segment in self.segments)
    {
        CGRect segmentFrame;
        CGRectDivide(bounds, &segmentFrame, &bounds, segmentWidth, CGRectMinXEdge);
        segment.frame = segmentFrame;
        // Divider
        CGRectDivide(bounds, &segmentFrame, &bounds, dividerWidth, CGRectMinXEdge);
    }
    return;
}

#pragma mark -

- (void)segmentTapped:(UITapGestureRecognizer *)sender
{
    __weak typeof(self) weakSelf = self;
    [self.segments enumerateObjectsUsingBlock:^(DQQuantifiedSegment *segment, NSUInteger idx, BOOL *stop) {
        if (sender.view == segment)
        {
            [weakSelf setSelectedSegmentIndex:idx];
            if (NULL != stop) {
                *stop = YES;
            }
        }
    }];
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    if (selectedSegmentIndex != _selectedSegmentIndex)
    {
        _selectedSegmentIndex = selectedSegmentIndex;
        __weak typeof(self) weakSelf = self;
        [self.segments enumerateObjectsUsingBlock:^(DQQuantifiedSegment *segment, NSUInteger idx, BOOL *stop) {
            segment.selected = (idx == selectedSegmentIndex);
            if (idx == selectedSegmentIndex)
            {
                [weakSelf.delegate segmentedControl:weakSelf didSelectSegmentAtIndex:idx];
            }
        }];
    }
}

- (void)setCount:(NSString *)count forSegmentIndex:(NSInteger)index
{
    if (count)
    {
        DQQuantifiedSegment *segment = [self.segments objectAtIndex:index];
        segment.count.text = count;
        [self setNeedsLayout];
    }
}

@end
