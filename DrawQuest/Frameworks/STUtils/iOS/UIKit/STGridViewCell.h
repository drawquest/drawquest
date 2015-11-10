//
//  STGridViewCell.h
//
//

@class STGridView;

@interface STGridViewCell : UIView {
    NSString *reuseIdentifier;
    NSString *cellIdentifier;
    NSIndexPath *indexPath;
    CGSize preferredContentSize;
    BOOL selected;
}

@property (nonatomic, retain) NSString *reuseIdentifier;
@property (nonatomic, assign) CGSize preferredContentSize;

// designated initializer
- (id)initWithReuseIdentifier:(NSString *)identifier;

- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithReuseIdentifier:);

- (void)setSelected:(BOOL)inSelected;
- (void)prepareForReuse;

@end
