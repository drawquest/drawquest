//
//  STGridView.h
//
//  Created by Buzz Andersen on 4/22/11.
//

#import <Foundation/Foundation.h>


typedef double STGridViewCellPriority;

typedef enum {
    STGridViewPullDownViewStatePullDown,
    STGridViewPullDownViewStateRelease,
    STGridViewPullDownViewStatePulledDown
} STGridViewPullDownViewState;

@class STGridView;
@class STGridViewCell;

@protocol STGridViewDataSource

- (NSInteger)numberOfSectionsInSTGridView:(STGridView *)inGridView;
- (NSInteger)STGridView:(STGridView *)inGridView numberOfCellsInSection:(NSInteger)inSection;

- (NSInteger)numberOfColumnsForSection:(NSInteger)inSection inSTGridView:(STGridView *)inGridView;
- (NSInteger)minimumCellColumnSpanForSection:(NSInteger)inSection inSTGridView:(STGridView *)inGridView;

- (STGridViewCell *)STGridView:(STGridView *)inGridView cellForIndexPath:(NSIndexPath *)inIndexPath;
- (STGridViewCellPriority)STGridView:(STGridView *)inGridView priorityForCellAtIndexPath:(NSIndexPath *)inIndexPath;

@end


@protocol STGridViewDelegate <UIScrollViewDelegate>

@optional
// Cell Height
- (CGFloat)STGridView:(STGridView *)inGridView minimumRowHeightForSection:(NSInteger)inSection;
- (CGFloat)STGridView:(STGridView *)inGridView preferredRowHeightForCellAtIndexPath:(NSIndexPath *)inIndexPath;

// Headers and Footers
- (CGFloat)STGridView:(STGridView *)gridView heightForHeaderInSection:(NSInteger)inSection;
- (CGFloat)STGridView:(STGridView *)gridView heightForFooterInSection:(NSInteger)inSection;
- (UIView *)STGridView:(STGridView *)gridView viewForHeaderInSection:(NSInteger)inSection;
- (UIView *)STGridView:(STGridView *)gridView viewForFooterInSection:(NSInteger)inSection;

// Section background views
- (UIView *)STGridView:(STGridView *)gridView backgroundViewForSection:(NSInteger)section;

- (UIEdgeInsets)STGridView:(STGridView *)gridView insetsForSection:(NSInteger)inSection;

- (void)STGridView:(STGridView *)tableView willDisplayCell:(STGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)STGridView:(STGridView *)inGridView didSelectCellAtIndexPath:(NSIndexPath *)inIndexPath;

- (void)STGridView:(STGridView *)inGridView pullDownViewTransitionedToState:(STGridViewPullDownViewState)inPullDownState;

@end


@interface STGridView : UIScrollView

@property (nonatomic, weak) id<STGridViewDataSource> dataSource;
@property (nonatomic, weak) id<STGridViewDelegate> delegate;
@property (nonatomic, strong) UIView *pullDownView;
@property (nonatomic, assign) CGFloat pullDownThreshold;
@property (nonatomic, assign) STGridViewPullDownViewState pullDownState;
@property (nonatomic, strong) UIView *gridHeaderView;
@property (nonatomic, strong) UIView *noDataView;

// Layout
- (void)reloadData;

// Cell Reuse
- (STGridViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

// Cell Access
- (void)selectCellAtIndexPath:(NSIndexPath *)inIndexPath;
- (STGridViewCell *)cellAtIndexPath:(NSIndexPath *)inIndexPath;

@end