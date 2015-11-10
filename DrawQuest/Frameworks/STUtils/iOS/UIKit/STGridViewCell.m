//
//  STGridViewCell.m
//


#import "STGridViewCell.h"
#import "STGridView.h"
#import "STUtils.h"


@interface STGridViewCell ()

@property (nonatomic, weak) STGridView *gridView;
@property (nonatomic, retain) NSString *cellIdentifier;
@property (nonatomic, retain) NSIndexPath *indexPath;

@end


@implementation STGridViewCell

@synthesize reuseIdentifier;
@synthesize cellIdentifier;
@synthesize indexPath;
@synthesize preferredContentSize;

#pragma mark Initialization

- (id)initWithReuseIdentifier:(NSString *)identifier;
{
    if ((self = [super initWithFrame:CGRectZero])) {
        self.reuseIdentifier = identifier;
        self.cellIdentifier = [NSString UUIDString];
        self.preferredContentSize = CGSizeZero;
    }
    return self;
}

- (void)dealloc;
{
    self.reuseIdentifier = nil;
}

- (void)setSelected:(BOOL)inSelected
{
    if(selected == inSelected) {
        return;
    }
    
    selected = inSelected;
}

#pragma mark UIView

- (void)didMoveToSuperview
{
    self.gridView = (STGridView *)[self superview];
}

#pragma mark -
#pragma UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setSelected:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setSelected:NO];
    [self.gridView selectCellAtIndexPath:self.indexPath];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setSelected:NO];
}

#pragma mark NSObject

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p (frame: %@; cell identifier: %@; reuse identifier: %@)>", NSStringFromClass([self class]), (void *)self, STStringFromRect(self.frame), self.cellIdentifier, self.reuseIdentifier];
}

#pragma mark Public Methods

- (void)prepareForReuse;
{
    self.indexPath = nil;
}

@end
