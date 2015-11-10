//
//  STGridView.m
//
//  Created by Buzz Andersen on 4/22/11.
//

// TO DO:
// - Adjust how reuse queue is sized to take into account that sections can have
//   more variable row heights now.

#import "STGridView.h"
#import "STGridViewCell.h"
#import "STUtils.h"


@interface STGridViewLayoutItem : NSObject {
    NSIndexPath *indexPath;
    STGridViewCellPriority priority;
    CGFloat preferredHeight;
    CGSize minimumSize;
    CGRect frame;
}

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) STGridViewCellPriority priority;
@property (nonatomic, assign) CGFloat preferredHeight;
@property (nonatomic, assign) CGSize minimumSize;
@property (nonatomic, assign) CGRect frame;

@end


@interface STGridViewLayoutSection : NSObject {
    NSInteger index;
    NSMutableArray *items;
    CGRect frame;
    CGFloat minimumRowHeight;
    CGFloat headerHeight;    
    CGFloat footerHeight;
    NSInteger numberOfColumns;
    NSInteger minimumItemColumnSpan;
    UIEdgeInsets contentInsets;
    CGRect contentFrame;
}

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, readonly) CGFloat columnWidth;
@property (nonatomic, assign) CGFloat minimumRowHeight;
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@property (nonatomic, assign) NSInteger numberOfColumns;
@property (nonatomic, assign) NSInteger minimumItemColumnSpan;
@property (nonatomic, assign) UIEdgeInsets contentInsets;

- (void)addItem:(STGridViewLayoutItem *)inItem;
- (void)layoutItems;
- (CGSize)gridAdjustedSizeForItem:(STGridViewLayoutItem *)inItem;
- (CGFloat)gridAdjustedWidthForWidth:(CGFloat)inWidth;
- (CGFloat)itemWidthForPriority:(STGridViewCellPriority)inPriority;
- (NSInteger)maximumItemCountForVisibleBounds:(CGRect)inBounds;
- (void)adjustItemsInRange:(NSRange)inRange toFillWidth:(CGFloat)inWidth;
- (void)adjustItemsInRange:(NSRange)inRange toFitHeight:(CGFloat)inHeight;
- (CGRect)contentRect;

@end


@interface STGridViewLayout : NSObject {
    NSMutableArray *sections;
    CGSize contentSize;
    CGFloat topOffset;
}

@property (nonatomic, strong) NSMutableArray *sections;
@property (nonatomic, assign) CGSize contentSize;
@property (nonatomic, assign, readonly) CGFloat itemPreloadMargin;
@property (nonatomic, assign) CGFloat topOffset;
@property (nonatomic, assign) CGFloat gridViewHeaderHeight;
@property (nonatomic, readonly) BOOL isEmpty;
@property (nonatomic, readonly) NSInteger totalItemCount;

- (void)setFrameWidth:(CGFloat)inFrameWidth forSection:(NSInteger)inSectionIndex;
- (void)setMinimumRowHeight:(CGFloat)inRowHeight forSection:(NSInteger)inSectionIndex;
- (void)setHeaderHeight:(CGFloat)inHeaderHeight forSection:(NSInteger)inSectionIndex;
- (void)setFooterHeight:(CGFloat)inFooterHeight forSection:(NSInteger)inSectionIndex;
- (void)setContentInsets:(UIEdgeInsets)insets forSection:(NSInteger)inSectionIndex;
- (void)setNumberOfColumns:(NSInteger)inNumberOfColumns forSection:(NSInteger)inSectionIndex;
- (void)setMinimumItemColumnSpan:(NSInteger)inMinimumColumnSpan forSection:(NSInteger)inSectionIndex;
- (void)addLayoutItemForCellWithPriority:(STGridViewCellPriority)inPriority preferredHeight:(CGFloat)inPreferredHeight indexPath:(NSIndexPath *)inIndexPath;
- (void)layoutSections;
- (NSIndexSet *)sectionIndicesForVisibleRect:(CGRect)inVisibleRect;
- (BOOL)sectionWithIndex:(NSInteger)inSectionIndex isVisibleForRect:(CGRect)inVisibleRect;
- (NSIndexSet *)visibleItemIndicesForSectionWithIndex:(NSInteger)sectionIndex andVisibleRect:(CGRect)inVisibleRect;
- (BOOL)headerForSectionWithIndex:(NSInteger)sectionIndex isVisibleInRect:(CGRect)inRect;
- (BOOL)footerForSectionWithIndex:(NSInteger)sectionIndex isVisibleInRect:(CGRect)inRect;
- (CGRect)backgroundViewRectForSection:(NSInteger)inSectionIndex;
- (CGRect)headerRectForSection:(NSInteger)inSectionIndex;
- (CGRect)footerRectForSection:(NSInteger)inSectionIndex;
- (STGridViewLayoutSection *)sectionWithIndex:(NSInteger)sectionIndex;
- (NSInteger)maximumRecyclableItemCountForVisibleBounds:(CGRect)inBounds;

@end


@interface STGridView ()

@property (nonatomic, strong) NSMutableArray *visibleCells;
@property (nonatomic, strong) NSMutableArray *visibleHeadersAndFooters;
@property (nonatomic, strong) NSMutableArray *visibleBackgroundViews;
@property (nonatomic, assign, readonly) CGRect visibleRect;
@property (nonatomic, strong) NSMutableDictionary *recycledCells;
@property (nonatomic, strong) STGridViewLayout *layout;

- (BOOL)_hasVisibleCellForLayoutItem:(STGridViewLayoutItem *)inLayoutItem;
- (void)_removeUnusedBackgroundViews;
- (void)_removeUnusedHeaderAndFooterViews;
- (void)_enqueueUnusedCellsForReuse;

@end


@interface STGridViewCell ()

@property (nonatomic, strong) NSIndexPath *indexPath;

@end

#pragma mark -
#pragma mark STGridViewLayoutItem
#pragma mark -

@implementation STGridViewLayoutItem

@synthesize indexPath;
@synthesize priority;
@synthesize preferredHeight;
@synthesize minimumSize;
@synthesize frame;

- (id)init;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.priority = 0;
    self.preferredHeight = 0.0;
    self.minimumSize = CGSizeMake(100.0, 100.0);
    self.frame = CGRectZero;
    
    return self;
}

- (void)dealloc;
{
    self.indexPath = nil;
}

#pragma mark NSObject

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p (frame: %@; priority: %f; preferred height: %f; minimum size: %@)>", NSStringFromClass([self class]), (void *)self, STStringFromRect(self.frame), self.priority, self.preferredHeight, STStringFromSize(self.minimumSize)];
}

@end


#pragma mark -
#pragma mark STGridViewLayoutSection
#pragma mark -

@implementation STGridViewLayoutSection

@synthesize index;
@synthesize items;
@synthesize frame;
@synthesize numberOfColumns;
@synthesize columnWidth;
@synthesize minimumItemColumnSpan;
@synthesize minimumRowHeight;
@synthesize headerHeight;
@synthesize footerHeight;
@synthesize contentInsets;

#pragma mark Initialization

- (id)init;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.index = 0;
    self.frame = CGRectZero;
    self.numberOfColumns = 6;
    self.minimumItemColumnSpan = 2;
    self.minimumRowHeight = 50.0;
    self.headerHeight = 0.0;
    self.footerHeight = 0.0;
    
    return self;
}

- (void)dealloc;
{
    self.items = nil;
}

#pragma mark Public Methods

- (void)addItem:(STGridViewLayoutItem *)inItem;
{
    [self.items addObject:inItem];
}

#pragma mark Accessors

- (CGFloat)columnWidth;
{
    return floor([self contentRect].size.width / self.numberOfColumns);
}

- (CGSize)minimumItemSize;
{
    return CGSizeMake(floor([self contentRect].size.width  / self.numberOfColumns) * self.minimumItemColumnSpan, self.minimumRowHeight);
}

- (NSMutableArray *)items;
{
    if (!items) {
        items = [[NSMutableArray alloc] init];
    }
    
    return items;
}

#pragma mark Layout

- (void)layoutItems;
{
    if (!self.items.count) {
        return;
    }
    
    // Origin and width of section frame should be set by the
    // parent layout object as it lays out the sections.
    // This method only adjusts the section's frame height.
    CGRect sectionFrame = self.frame;

    // Frames of items are relative to the enclosing
    // section
    CGRect contentRect = [self contentRect];
    CGFloat currentX = CGRectGetMinX(contentRect);
    CGFloat currentY = self.headerHeight + self.contentInsets.top;
    
    NSInteger currentLayoutItemIndex = 0;
    NSInteger currentRowStartIndex = 0;
    CGFloat currentRowMaxHeight = self.minimumRowHeight;
    CGFloat currentRowItemsWidth = 0.0;
    CGFloat requiredRowItemWidth = self.numberOfColumns * self.columnWidth;
    
    for (STGridViewLayoutItem *currentItem in self.items) {
        // Get the item size with priority taken into account
        CGSize adjustedSize = [self gridAdjustedSizeForItem:currentItem];
        
        // Should current item be on new row?
        if ((currentX + adjustedSize.width) > sectionFrame.size.width) {
            NSRange currentRowRange = NSMakeRange(currentRowStartIndex, currentLayoutItemIndex - currentRowStartIndex);
            
            // Will putting the current item on a new row leave a gap
            // on the current row?
            if (currentRowItemsWidth < requiredRowItemWidth) {
                // Adjust the current row to fill the gap 
                CGFloat excessWidth = requiredRowItemWidth - currentRowItemsWidth;
                [self adjustItemsInRange:currentRowRange toFillWidth:excessWidth];
            }
            
            currentX = CGRectGetMinX([self contentRect]);
            currentY += currentRowMaxHeight;   
            sectionFrame.size.height += currentRowMaxHeight;
            
            [self adjustItemsInRange:currentRowRange toFitHeight:currentRowMaxHeight];
            
            currentRowMaxHeight = self.minimumRowHeight;
            currentRowStartIndex = currentLayoutItemIndex;
        }
        
        if (currentItem.preferredHeight > currentRowMaxHeight) {
            currentRowMaxHeight = currentItem.preferredHeight;
        }
        
        CGRect itemRect = CGRectMake(currentX, currentY, adjustedSize.width, adjustedSize.height);
        currentItem.frame = itemRect;
        
        // Add new column for next item
        currentX += adjustedSize.width;
        currentRowItemsWidth = currentX;
        
        currentLayoutItemIndex++;
    }
    
    // Get the height of the last row added in
    sectionFrame.size.height += currentRowMaxHeight;
    sectionFrame.size.height += self.footerHeight;
    sectionFrame.size.height += self.contentInsets.bottom;
    
    self.frame = sectionFrame;
}

- (CGSize)gridAdjustedSizeForItem:(STGridViewLayoutItem *)inItem;
{
    CGFloat adjustedWidth = [self itemWidthForPriority:inItem.priority];
    return CGSizeMake(adjustedWidth, inItem.preferredHeight);
}

- (CGFloat)gridAdjustedWidthForWidth:(CGFloat)inWidth;
{
    if (inWidth < self.minimumItemSize.width) {
        return self.minimumItemSize.width;
    }
    
    return (inWidth / self.numberOfColumns) * self.numberOfColumns;
}

- (CGFloat)itemWidthForPriority:(STGridViewCellPriority)inPriority;
{
    if (inPriority == 0.0) {
        return self.minimumItemSize.width;
    }
    
    return floor(self.numberOfColumns * inPriority) * self.columnWidth;
}

- (NSInteger)maximumItemCountForVisibleBounds:(CGRect)inBounds;
{
    CGSize minimumSize = self.minimumItemSize;
    return floor((inBounds.size.width / minimumSize.width) * (inBounds.size.height / minimumSize.height));
}

- (void)adjustItemsInRange:(NSRange)inRange toFillWidth:(CGFloat)inWidth;
{
    STGridViewLayoutItem *item = [self.items objectAtIndex:inRange.location + (inRange.length - 1)];
    item.frame = STRectAdjustedByWidth(item.frame, inWidth);
}

- (void)adjustItemsInRange:(NSRange)inRange toFitHeight:(CGFloat)inHeight;
{
    for (NSInteger i = inRange.location; i < (inRange.location + inRange.length); i++) {
        STGridViewLayoutItem *item = [self.items objectAtIndex:i];
        item.frame = CGRectMake(item.frame.origin.x, item.frame.origin.y, item.frame.size.width, inHeight);
    }
}

- (CGRect)contentRect
{
    return UIEdgeInsetsInsetRect(self.frame, self.contentInsets);
}

#pragma mark NSObject

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p (index: %ld; frame: %@; minimum row height: %f; number of columns: %ld; minimum item span: %ld; item count: %lu)>", NSStringFromClass([self class]), (void *)self, (long)self.index, STStringFromRect(self.frame), self.minimumRowHeight, (long)self.numberOfColumns, (long)self.minimumItemColumnSpan, (unsigned long)self.items.count];
}

@end


#pragma mark -
#pragma mark STGridViewLayout
#pragma mark -

@implementation STGridViewLayout

@synthesize sections;
@synthesize contentSize;
@synthesize topOffset;
@synthesize gridViewHeaderHeight;

#pragma mark Initialization

- (id)init;
{
    if (!(self = [super init])) {
        return nil;
    }
    
    self.topOffset = 0.0;
    self.gridViewHeaderHeight = 0.0;
    
    return self;
}

- (void)dealloc;
{
    self.sections = nil;
}

#pragma mark Accessors

- (BOOL)isEmpty;
{
    return self.totalItemCount < 1;
}

- (NSInteger)totalItemCount;
{
    if (self.sections.count < 1) {
        return 0;
    }
    
    NSInteger itemCount = 0;
    for (STGridViewLayoutSection *currentSection in self.sections) {
        itemCount += currentSection.items.count;
    }
    
    return itemCount;
}

- (void)setGridViewHeaderHeight:(CGFloat)inGridViewHeaderHeight
{
    BOOL headerHeightChanged = (inGridViewHeaderHeight != gridViewHeaderHeight);
    gridViewHeaderHeight = inGridViewHeaderHeight;
    
    if (headerHeightChanged) {
        [self layoutSections];
    }
}

- (void)setTopOffset:(CGFloat)inTopOffset;
{
    BOOL topOffsetChanged = (inTopOffset != topOffset);
    topOffset = inTopOffset;
    
    if (topOffsetChanged) {
        [self layoutSections];
    }
}

- (NSMutableArray *)sections;
{
    if (!sections) {
        sections = [[NSMutableArray alloc] init];
    }
    
    return sections;
}

- (STGridViewLayoutSection *)sectionWithIndex:(NSInteger)inSectionIndex;
{    
    for (STGridViewLayoutSection *currentSection in self.sections) {
        if (currentSection.index == inSectionIndex) {
            return currentSection;
        }
    }
    
    // Didn't find a matching section, create one
    STGridViewLayoutSection *newSection = [[STGridViewLayoutSection alloc] init];
    newSection.index = inSectionIndex;
    [self.sections addObject:newSection];
    
    return newSection;
}

- (void)setFrameWidth:(CGFloat)inFrameWidth forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    CGRect sectionFrame = section.frame;
    sectionFrame.size.width = inFrameWidth;
    section.frame = sectionFrame;
}

- (void)setMinimumRowHeight:(CGFloat)inRowHeight forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    section.minimumRowHeight = inRowHeight;
}

- (void)setHeaderHeight:(CGFloat)inHeaderHeight forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    section.headerHeight = inHeaderHeight;
    
    [self layoutSections];
}

- (void)setFooterHeight:(CGFloat)inFooterHeight forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    section.footerHeight = inFooterHeight;
}

- (void)setContentInsets:(UIEdgeInsets)insets forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    section.contentInsets = insets;
    
    [self layoutSections];
}

- (void)setNumberOfColumns:(NSInteger)inNumberOfColumns forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    section.numberOfColumns = inNumberOfColumns;
}

- (void)setMinimumItemColumnSpan:(NSInteger)inMinimumColumnSpan forSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    section.minimumItemColumnSpan = inMinimumColumnSpan;
}

#pragma mark Public Methods

- (void)addLayoutItemForCellWithPriority:(STGridViewCellPriority)inPriority preferredHeight:(CGFloat)inPreferredHeight indexPath:(NSIndexPath *)inIndexPath;
{
    STGridViewLayoutItem *newItem = [[STGridViewLayoutItem alloc] init];
    newItem.priority = inPriority;
    newItem.indexPath = inIndexPath;
    newItem.preferredHeight = inPreferredHeight;

    STGridViewLayoutSection *section = [self sectionWithIndex:inIndexPath.section];
    [section addItem:newItem];
}

- (void)layoutSections;
{
    if (!self.sections.count) {
        return;
    }
    
    CGFloat contentWidth = 0.0f;
    CGFloat contentHeight = self.gridViewHeaderHeight + self.topOffset;
    
    for (STGridViewLayoutSection *currentSection in self.sections) {
        // First layout the section's items so we know how big it is
        [currentSection layoutItems];

        // Set the section's origin relative to the preceeding sections
        currentSection.frame = CGRectMake(0.0, contentHeight, currentSection.frame.size.width, currentSection.frame.size.height);
        
        // Add the current section's height to the overall layout height
        contentHeight += currentSection.frame.size.height;
        
        // All sections should be the same width, but just to be
        // defensive, we'll make sure to set the overall layout
        // width to the width of the widest row.
        if (currentSection.frame.size.width > contentWidth) {
            contentWidth = currentSection.frame.size.width;
        }
    }
    
    self.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (BOOL)sectionWithIndex:(NSInteger)inSectionIndex isVisibleForRect:(CGRect)inVisibleRect;
{
    NSIndexSet *visibleIndices = [self sectionIndicesForVisibleRect:inVisibleRect];
    return [visibleIndices containsIndex:inSectionIndex];
}

- (NSIndexSet *)sectionIndicesForVisibleRect:(CGRect)inVisibleRect;
{
    NSMutableIndexSet *sectionIndices = [NSMutableIndexSet indexSet];
    
    CGFloat visibleBottom = inVisibleRect.origin.y + inVisibleRect.size.height;
    
    for (int i = 0; i < self.sections.count; i++) {
        STGridViewLayoutSection *currentSection = [self sectionWithIndex:i];
        
        if (currentSection.frame.origin.y > visibleBottom) {
            break;
        } else if (CGRectIntersectsRect(inVisibleRect, currentSection.frame)) {
            [sectionIndices addIndex:i];
        }
    }
    
    return sectionIndices;
}

- (NSIndexSet *)visibleItemIndicesForSectionWithIndex:(NSInteger)sectionIndex andVisibleRect:(CGRect)inVisibleRect;
{
    if (sectionIndex >= self.sections.count) {
        return nil;
    }
        
    CGFloat visibleRectTop = inVisibleRect.origin.y;
    CGFloat visibleRectBottom = visibleRectTop + inVisibleRect.size.height;
    
    STGridViewLayoutSection *section = [self sectionWithIndex:sectionIndex];
    CGFloat sectionTop = section.frame.origin.y;
    CGFloat sectionBottom = section.frame.origin.y + section.frame.size.height;
    
    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
    
    // If the section is not within the visible rect,
    // none of its cells are visible
    if (sectionTop > visibleRectBottom || sectionBottom < visibleRectTop) {
        return indices;
    }
    
    for (NSInteger i = 0; i < section.items.count; i++) {
        STGridViewLayoutItem *currentItem = [section.items objectAtIndex:i];
        CGFloat currentItemTop = section.frame.origin.y + currentItem.frame.origin.y;
        CGFloat currentItemBottom = currentItemTop + currentItem.frame.size.height;
        
        if (currentItemBottom > visibleRectTop && currentItemTop < visibleRectBottom) {
            [indices addIndex:i];
        }
        
        if (currentItemTop > visibleRectBottom) {
            break;
        }
    }
    
    return indices;
}

- (CGRect)backgroundViewRectForSection:(NSInteger)inSectionIndex
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    return CGRectMake(section.frame.origin.x, section.frame.origin.y + section.headerHeight + self.topOffset, section.frame.size.width, section.frame.size.height - (section.headerHeight + section.footerHeight));
}

- (CGRect)headerRectForSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    return CGRectMake(section.frame.origin.x, section.frame.origin.y, section.frame.size.width, section.headerHeight);
}

- (CGRect)footerRectForSection:(NSInteger)inSectionIndex;
{
    STGridViewLayoutSection *section = [self sectionWithIndex:inSectionIndex];
    return CGRectMake(section.frame.origin.x, section.frame.origin.y + (section.frame.size.height - section.footerHeight), section.frame.size.width, section.footerHeight);
}

- (BOOL)headerForSectionWithIndex:(NSInteger)inSectionIndex isVisibleInRect:(CGRect)inRect;
{
    return CGRectIntersectsRect(inRect, [self headerRectForSection:inSectionIndex]);
}

- (BOOL)footerForSectionWithIndex:(NSInteger)inSectionIndex isVisibleInRect:(CGRect)inRect;
{
    return CGRectIntersectsRect(inRect, [self footerRectForSection:inSectionIndex]);
}

- (NSInteger)maximumRecyclableItemCountForVisibleBounds:(CGRect)inBounds;
{
    NSInteger highestMaxVisibleCount = 0;
    
    for (STGridViewLayoutSection *currentSection in self.sections) {
        NSInteger currentMaxVisibleCount = [currentSection maximumItemCountForVisibleBounds:inBounds];
        
        if (currentMaxVisibleCount > highestMaxVisibleCount) {
            highestMaxVisibleCount = currentMaxVisibleCount;
        }
    }
    
    return floor(highestMaxVisibleCount * 2);
}

- (CGFloat)itemPreloadMargin;
{
    CGFloat largestRowHeight = 0.0f;
    
    for (STGridViewLayoutSection *currentSection in self.sections) {
        CGFloat currentSectionRowHeight = currentSection.minimumRowHeight;
        
        if (currentSectionRowHeight > largestRowHeight) {
            largestRowHeight = currentSectionRowHeight;
        }
    }
    
    return largestRowHeight * 6.0f;
}

#pragma mark NSObject

- (NSString *)description;
{
    NSMutableString *descriptionString = [NSMutableString string];
    [descriptionString appendFormat:@"<%@: %p (section count: %lu)>(\n", NSStringFromClass([self class]), (void *)self, (unsigned long)self.sections.count];

    for (STGridViewLayoutSection *currentSection in self.sections) {
        [descriptionString appendFormat:@"\t%@(\n", currentSection];
        
        for (STGridViewLayoutItem *currentItem in currentSection.items) {
            [descriptionString appendFormat:@"\t\t%@\n", currentItem];
        }
        
        [descriptionString appendString:@"\t)\n"];
    }
    
    [descriptionString appendString:@")\n"];
    return descriptionString;
}

@end


#pragma mark -
#pragma mark STGridView
#pragma mark -

@implementation STGridView
{
    STGridViewLayout *layout;

    NSMutableArray *visibleCells;
    NSMutableArray *visibleHeadersAndFooters;
    NSMutableDictionary *recycledCells;

    __weak id <STGridViewDataSource> dataSource;

    UIView *pullDownView;
    CGFloat pullDownThreshold;
    STGridViewPullDownViewState pullDownState;

    UIView *noDataView;
}

@synthesize layout;
@synthesize visibleCells;
@synthesize visibleBackgroundViews;
@synthesize visibleHeadersAndFooters;
@synthesize recycledCells;
@synthesize pullDownView;
@synthesize pullDownThreshold;
@synthesize pullDownState;
@synthesize gridHeaderView;
@synthesize noDataView;
@synthesize dataSource;
@dynamic delegate;

#pragma mark Initialization

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self)
    {
        pullDownThreshold = 50.0;
    }
    return self;
}

#pragma mark Accessors

- (void)setContentOffset:(CGPoint)inContentOffset;
{
    [super setContentOffset:inContentOffset];
    
    if (!self.pullDownView) {
        return;
    }
    
    CGFloat fullPullThreshold = -(self.pullDownView.frame.size.height + self.pullDownThreshold);
        
    if (self.pullDownState == STGridViewPullDownViewStatePullDown && inContentOffset.y < fullPullThreshold) {
        self.pullDownState = STGridViewPullDownViewStateRelease;
        return;
    } 
    
    if (self.pullDownState == STGridViewPullDownViewStateRelease && inContentOffset.y >= fullPullThreshold) {
        if (self.tracking) {
            self.pullDownState = STGridViewPullDownViewStatePullDown;
        } else {
            self.pullDownState = STGridViewPullDownViewStatePulledDown;
        }
    }
}

- (void)setPullDownState:(STGridViewPullDownViewState)inPullDownState;
{
    pullDownState = inPullDownState;
    
    if ([self.delegate respondsToSelector:@selector(STGridView:pullDownViewTransitionedToState:)]) {
        [self.delegate STGridView:self pullDownViewTransitionedToState:inPullDownState];
    }
    
    if (inPullDownState == STGridViewPullDownViewStatePulledDown) {
        self.contentInset = UIEdgeInsetsMake(self.pullDownView.frame.size.height, 0.0, 0.0, 0.0);
    } else if (inPullDownState == STGridViewPullDownViewStatePullDown) {
        [UIView beginAnimations:nil context:NULL];
            self.contentInset = UIEdgeInsetsZero;
        [UIView commitAnimations];
    }
    
    [self setNeedsLayout];
}

- (void)setPullDownView:(UIView *)inPullDownView;
{
    [pullDownView removeFromSuperview];
    
    pullDownView = inPullDownView;
    
    [self addSubview:inPullDownView];
    
    [self setNeedsLayout];
}

- (void)setNoDataView:(UIView *)inNoDataView;
{
    [noDataView removeFromSuperview];
    
    noDataView = inNoDataView;
    
    if (self.layout.isEmpty) {
        CGRect noDataRect = [self centeredSubRectOfSize:inNoDataView.frame.size];
        inNoDataView.frame = noDataRect;
        [self addSubview:inNoDataView];
    }
}

- (void)setGridHeaderView:(UIView *)inGridHeaderView
{
    [gridHeaderView removeFromSuperview];
    
    gridHeaderView = inGridHeaderView;
    
    [self addSubview:inGridHeaderView];
}

- (NSMutableArray *)visibleCells;
{
    if (!visibleCells) {
        visibleCells = [[NSMutableArray alloc] init];
    }
    
    return visibleCells;
}

- (NSMutableArray *)visibleBackgroundViews
{
    if (!visibleBackgroundViews) {
        visibleBackgroundViews = [[NSMutableArray alloc] init];
    }
    
    return visibleBackgroundViews;
}

- (void)setVisibleBackgroundViews:(NSMutableArray *)inVisibleBackgroundViews
{
    if (visibleBackgroundViews) {
        [visibleBackgroundViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }

    visibleBackgroundViews = inVisibleBackgroundViews;
}

- (NSMutableArray *)visibleHeadersAndFooters;
{
    if (!visibleHeadersAndFooters) {
        visibleHeadersAndFooters = [[NSMutableArray alloc] init];
    }
    
    return visibleHeadersAndFooters;
}

- (void)setVisibleHeadersAndFooters:(NSMutableArray *)inVisibleHeadersAndFooters
{
    if (visibleHeadersAndFooters) {
        [visibleHeadersAndFooters makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    visibleHeadersAndFooters = inVisibleHeadersAndFooters;
    
}

- (NSMutableDictionary *)recycledCells;
{
    if (!recycledCells) {
        recycledCells = [[NSMutableDictionary alloc] init];
    }
    
    return recycledCells;
}

- (STGridViewLayout *)layout;
{
    if (!layout) {
        layout = [[STGridViewLayout alloc] init];
    }
    
    return layout;
}

- (CGRect)visibleRect;
{
    return CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height);
}

#pragma mark UIView

- (void)layoutSubviews;
{    
    [self _enqueueUnusedCellsForReuse];
    [self _removeUnusedBackgroundViews];
    [self _removeUnusedHeaderAndFooterViews];
    
    // Set up the pull down view
    if (self.pullDownView) {
        CGFloat pullDownViewHeight = self.pullDownView.frame.size.height;
        self.pullDownView.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y - pullDownViewHeight, self.pullDownView.frame.size.width, self.pullDownView.frame.size.height);
    }
    
    // Set up the grid header view
    CGFloat gridHeaderViewHeight = 0.0;
    if (self.gridHeaderView) {
        gridHeaderViewHeight = CGRectGetHeight(self.gridHeaderView.frame);
        self.gridHeaderView.frame = CGRectMake(CGRectGetMinX(self.gridHeaderView.frame), CGRectGetMinY(self.gridHeaderView.frame), self.gridHeaderView.bounds.size.width, gridHeaderViewHeight);
    }
    
    CGRect visibleRect = self.visibleRect;
    NSIndexSet *visibleSectionIndices = [self.layout sectionIndicesForVisibleRect:visibleRect];
    
    CGFloat startingX = self.contentInset.left;
    CGFloat startingY = 0.0f; // /*gridHeaderViewHeight +*/ self.contentInset.top;
    
    // Iterate the visible sections
    NSInteger currentVisibleSectionIndex = [visibleSectionIndices firstIndex];
    while (currentVisibleSectionIndex != NSNotFound) {
        @autoreleasepool {
            STGridViewLayoutSection *currentSection = [self.layout sectionWithIndex:currentVisibleSectionIndex];
            
            if ([self.delegate respondsToSelector:@selector(STGridView:backgroundViewForSection:)] && currentSection.items.count > 0) {
                UIView *backgroundView = [self.delegate STGridView:self backgroundViewForSection:currentVisibleSectionIndex];
                if (backgroundView) {
                    CGRect backgroundFrame = [self.layout backgroundViewRectForSection:currentVisibleSectionIndex];
                    backgroundView.frame = CGRectOffset(backgroundFrame, startingX, startingY);
                    
                    [self addSubview:backgroundView];
                    [self sendSubviewToBack:backgroundView];
                    
                    [self.visibleBackgroundViews addObject:backgroundView];
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(STGridView:viewForHeaderInSection:)] && [self.layout headerForSectionWithIndex:currentVisibleSectionIndex isVisibleInRect:visibleRect]) {
                UIView *headerView = [self.delegate STGridView:self viewForHeaderInSection:currentVisibleSectionIndex];
                if (headerView) {
                    CGRect sectionHeaderFrame = [self.layout headerRectForSection:currentVisibleSectionIndex];
                    headerView.frame = CGRectOffset(sectionHeaderFrame, startingX, startingY);
                    
                    [self addSubview:headerView];
                    [self bringSubviewToFront:headerView];
                    
                    [self.visibleHeadersAndFooters addObject:headerView];
                }
            }
            
            // Iterate the visible layout items in each section
            NSIndexSet *visibleItemIndices = [self.layout visibleItemIndicesForSectionWithIndex:currentVisibleSectionIndex andVisibleRect:visibleRect];
            NSInteger currentVisibleItemIndex = [visibleItemIndices firstIndex];
            
            while (currentVisibleItemIndex != NSNotFound) {
                @autoreleasepool {
                    STGridViewLayoutItem *currentLayoutItem = [currentSection.items objectAtIndex:currentVisibleItemIndex];
                    
                    if ( ! [self _hasVisibleCellForLayoutItem:currentLayoutItem])
                    {
                        STGridViewCell *cell = [self.dataSource STGridView:self cellForIndexPath:currentLayoutItem.indexPath];
                        cell.indexPath = currentLayoutItem.indexPath;
                        
                        CGRect cellsFrame = CGRectOffset(currentLayoutItem.frame, startingX, startingY);
                        cell.frame = CGRectMake(cellsFrame.origin.x, [currentSection contentRect].origin.y + cellsFrame.origin.y, cellsFrame.size.width, cellsFrame.size.height);
                        
                        if ([(id)self.delegate respondsToSelector:@selector(STGridView:willDisplayCell:atIndexPath:)]) {
                            [self.delegate STGridView:self willDisplayCell:cell atIndexPath:currentLayoutItem.indexPath];
                        }
                        
                        [self addSubview:cell];
                        [self.visibleCells addObject:cell];
                    }
                    currentVisibleItemIndex = [visibleItemIndices indexGreaterThanIndex:currentVisibleItemIndex];
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(STGridView:viewForFooterInSection:)] && [self.layout footerForSectionWithIndex:currentVisibleSectionIndex isVisibleInRect:visibleRect]) {
                UIView *footerView = [self.delegate STGridView:self viewForFooterInSection:currentVisibleSectionIndex];
                
                if (footerView) {
                    CGRect footerRect = [self.layout footerRectForSection:currentVisibleSectionIndex];
                    footerView.frame = CGRectOffset(footerRect, startingX, startingY);
                    [self addSubview:footerView];
                    [self.visibleHeadersAndFooters addObject:footerView];
                }
            }
            
            currentVisibleSectionIndex = [visibleSectionIndices indexGreaterThanIndex:currentVisibleSectionIndex];
        }
    }
}

#pragma mark Public Methods

- (void)reloadData;
{
    if (!self.dataSource) {
        return;
    }
    
    [self _enqueueVisibleCellsForReuse];
    [self.visibleHeadersAndFooters makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleBackgroundViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleHeadersAndFooters removeAllObjects];
    [self.visibleBackgroundViews removeAllObjects];
	
    NSInteger sectionCount = [self.dataSource numberOfSectionsInSTGridView:self];

    self.layout = nil;
    
    if (self.gridHeaderView) {
        self.layout.gridViewHeaderHeight = self.gridHeaderView.bounds.size.height;
    }
    
    for (int currentSection = 0; currentSection < sectionCount; currentSection++) {
        [self.layout setFrameWidth:self.bounds.size.width forSection:currentSection];
        
        if ([self.delegate respondsToSelector:@selector(STGridView:heightForHeaderInSection:)]) {
            CGFloat headerHeight = [self.delegate STGridView:self heightForHeaderInSection:currentSection];
            [self.layout setHeaderHeight:headerHeight forSection:currentSection];
        }
        
        if ([self.delegate respondsToSelector:@selector(STGridView:heightForFooterInSection:)]) {
            CGFloat footerHeight = [self.delegate STGridView:self heightForFooterInSection:currentSection];
            [self.layout setFooterHeight:footerHeight forSection:currentSection];
        }
        
        if ([self.delegate respondsToSelector:@selector(STGridView:insetsForSection:)]) {
            UIEdgeInsets sectionInsets = [self.delegate STGridView:self insetsForSection:currentSection];
            [self.layout setContentInsets:sectionInsets forSection:currentSection];
        }
        
        NSInteger numberOfColumns = [self.dataSource numberOfColumnsForSection:currentSection inSTGridView:self];
        [self.layout setNumberOfColumns:numberOfColumns forSection:currentSection];
        
        NSInteger minimumColumnSpan = [self.dataSource minimumCellColumnSpanForSection:currentSection inSTGridView:self];
        [self.layout setMinimumItemColumnSpan:minimumColumnSpan forSection:currentSection];
        
        NSInteger sectionCellCount = [self.dataSource STGridView:self numberOfCellsInSection:currentSection];
        
        for (int currentCellIndex = 0; currentCellIndex < sectionCellCount; currentCellIndex++) {
            @autoreleasepool {
                NSUInteger indices[2] = {currentSection, currentCellIndex};
                NSIndexPath *cellPath = [NSIndexPath indexPathWithIndexes:indices length:2];
                STGridViewCellPriority currentCellPriority = [self.dataSource STGridView:self priorityForCellAtIndexPath:cellPath];
                
                CGFloat cellHeight = 0.0;
                if ([self.delegate respondsToSelector:@selector(STGridView:preferredRowHeightForCellAtIndexPath:)]) {
                    cellHeight = [self.delegate STGridView:self preferredRowHeightForCellAtIndexPath:cellPath];
                }
                
                [self.layout addLayoutItemForCellWithPriority:currentCellPriority preferredHeight:cellHeight indexPath:cellPath];
            }
        }
    }
    
    [self.layout layoutSections];
    
    if (self.noDataView) {
        BOOL layoutIsEmpty = self.layout.isEmpty;
        self.noDataView.hidden = layoutIsEmpty ? NO : YES;
    }

    CGRect gridBounds = [self bounds];
    CGFloat contentHeight = self.layout.contentSize.height;
    
	if (contentHeight > gridBounds.size.height) {
        self.contentSize = CGSizeMake(gridBounds.size.width, contentHeight);
    } else {
		self.contentSize = CGSizeMake(gridBounds.size.width, gridBounds.size.height);
    }
    
    [self setNeedsLayout];
}

- (STGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)inIdentifier;
{
    NSMutableArray *reusableCellsForIdentifier = [self.recycledCells objectForKey:inIdentifier];
    
    if (!reusableCellsForIdentifier.count) {
        return nil;
    }
    
    STGridViewCell *foundCell = [reusableCellsForIdentifier lastObject];
    [reusableCellsForIdentifier removeObject:foundCell];
	
	return foundCell;
}

- (void)selectCellAtIndexPath:(NSIndexPath *)inIndexPath;
{
    if (!self.delegate || ![self.delegate respondsToSelector:@selector(STGridView:didSelectCellAtIndexPath:)]) {
        return;
    }
    
    [self.delegate STGridView:self didSelectCellAtIndexPath:inIndexPath];
}

- (STGridViewCell *)cellAtIndexPath:(NSIndexPath *)inIndexPath;
{
    // Make sure we have the specified section
    if (inIndexPath.section > self.layout.sections.count) {
        return nil;
    }
    
    // Make sure we have the specified cell within the section
    STGridViewLayoutSection *section = [self.layout.sections objectAtIndex:inIndexPath.section];
    if (inIndexPath.row > section.items.count) {
        return nil;
    }
    
    // Get the set of visible items within the section
    NSIndexSet *visibleItems = [self.layout visibleItemIndicesForSectionWithIndex:inIndexPath.section andVisibleRect:self.visibleRect];
    if (![visibleItems containsIndex:inIndexPath.row]) {
        return nil;
    }
    
    // Make sure the specified cell is within the range
    // of visible cells
    NSInteger firstVisibleIndex = [visibleItems firstIndex];
    NSInteger lastVisibleIndex = [visibleItems lastIndex];
    if (inIndexPath.row > lastVisibleIndex || inIndexPath.row < firstVisibleIndex) {
        return nil;
    }
    
    NSArray *sortedCells = [self.visibleCells sortedArrayUsingComparator:^(STGridViewCell *gridCell1, STGridViewCell *gridCell2) {
        return [gridCell1.indexPath compare:gridCell2.indexPath];
    }];
    
    NSInteger adjustedCellIndex = inIndexPath.row - firstVisibleIndex;
    return [sortedCells objectAtIndex:adjustedCellIndex];
}

#pragma mark Private Methods

- (BOOL)_hasVisibleCellForLayoutItem:(STGridViewLayoutItem *)inLayoutItem;
{
    for (STGridViewCell *currentCell in self.visibleCells) {
        if (currentCell.indexPath.section == inLayoutItem.indexPath.section && currentCell.indexPath.row == inLayoutItem.indexPath.row) {
            return YES;
        }
    }
    
    return NO;
}

- (void)_removeUnusedBackgroundViews
{
    CGFloat visibleTop = self.contentOffset.y;
    CGFloat visibleBottom = visibleTop + self.bounds.size.height;
    
    NSMutableArray *viewsToBeRemoved = [[NSMutableArray alloc] init];
    
    for (UIView *currentView in self.visibleBackgroundViews) {
        if (CGRectGetMaxY(currentView.frame) < visibleTop || currentView.frame.origin.y > visibleBottom) {
            [currentView removeFromSuperview];
            [viewsToBeRemoved addObject:currentView];
        }
    }
    
    [self.visibleBackgroundViews removeObjectsInArray:viewsToBeRemoved];
}

- (void)_removeUnusedHeaderAndFooterViews;
{
    CGFloat visibleTop = self.contentOffset.y;
    CGFloat visibleBottom = visibleTop + self.bounds.size.height;
    
    NSMutableArray *viewsToBeRemoved = [[NSMutableArray alloc] init];
    
    for (UIView *currentView in self.visibleHeadersAndFooters) {
        if (CGRectGetMaxY(currentView.frame) < visibleTop || currentView.frame.origin.y > visibleBottom) {
            [currentView removeFromSuperview];
            [viewsToBeRemoved addObject:currentView];
        }
    }
    
    [self.visibleHeadersAndFooters removeObjectsInArray:viewsToBeRemoved];
}

- (void)_enqueueUnusedCellsForReuse;
{
    NSInteger reusableCellLimit = [self.layout maximumRecyclableItemCountForVisibleBounds:self.bounds];
    
    CGFloat visibleTop = self.contentOffset.y;
    CGFloat visibleBottom = visibleTop + self.bounds.size.height;
    
    NSMutableArray *cellsToBeRemoved = [[NSMutableArray alloc] init];
        
    for (STGridViewCell *currentCell in self.visibleCells) {
        CGFloat cellTop = currentCell.frame.origin.y;
        CGFloat cellBottom = cellTop + currentCell.frame.size.height;
        
        if ((cellBottom < visibleTop) || (cellTop > visibleBottom)) {
            [cellsToBeRemoved addObject:currentCell];
            [self _enqueueCellForReuse:currentCell withReusableCellLimit:reusableCellLimit];
        }
    }
    
    [cellsToBeRemoved makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.visibleCells removeObjectsInArray:cellsToBeRemoved];
}

- (void)_enqueueVisibleCellsForReuse
{
    NSInteger reusableCellLimit = [self.layout maximumRecyclableItemCountForVisibleBounds:self.bounds];
    
    for (STGridViewCell *currentCell in self.visibleCells) {
        [self _enqueueCellForReuse:currentCell withReusableCellLimit:reusableCellLimit];
    }
    [self.visibleCells removeAllObjects];
}

- (void)_enqueueCellForReuse:(STGridViewCell *)cell withReusableCellLimit:(NSInteger)reusableCellLimit
{
    NSMutableArray *reusableCellsForIdentifier = [self.recycledCells objectForKey:cell.reuseIdentifier];
    
    if (!reusableCellsForIdentifier) {
        reusableCellsForIdentifier = [[NSMutableArray alloc] init];
        [self.recycledCells setObject:reusableCellsForIdentifier forKey:cell.reuseIdentifier];
    }
    
    if (reusableCellsForIdentifier.count < reusableCellLimit) {
        [cell prepareForReuse];
        [reusableCellsForIdentifier addObject:cell];
    }
    [cell removeFromSuperview];
}

@end