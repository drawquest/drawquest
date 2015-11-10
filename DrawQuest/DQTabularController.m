//
//  DQTabularController.m
//  DrawQuest
//
//  Created by Jeremy Tregunna on 2013-06-11.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "DQTabularController.h"
#import "DQTabularItem.h"

static NSUInteger DQTabularControllerButtonTagOffset = 2000;
static CGFloat DQTabularControllerButtonWidth = 158.0f;

@interface DQTabularController ()

@property (nonatomic, readwrite, copy) NSArray *items;
@property (nonatomic, readwrite, assign) NSUInteger selectedIndex;
@property (nonatomic, readonly, assign) CGFloat borderSpacing;
@property (nonatomic, strong) DQTabularItem *selectedItem;

@end

@implementation DQTabularController

@dynamic borderSpacing;

- (instancetype)initWithItems:(NSArray *)items delegate:(id<DQTabularControllerDelegate>)delegate startIndex:(NSUInteger)startIndex
{
    self = [super init];
    if (self)
    {
        _items = items;
        _selectedIndex = startIndex;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self reloadTabButtons];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    [self layoutTabButtons];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Adding / removing tab buttons

- (void)removeTabButtons
{
    NSArray *buttons = [self.view subviews];
    for(UIButton *button in buttons)
        [button removeFromSuperview];
}

- (void)addTabButtons
{
    for (NSUInteger i = 0; i < [self.items count]; i++)
    {
        UIButton *button = [self _buttonForItem:self.items[i] atIndex:i];
        CGRect buttonFrame = button.frame;
        buttonFrame.origin = [self _originForButtonAtIndex:i];
        button.frame = buttonFrame;
        [self.view addSubview:button];
    }
}

- (void)reloadTabButtons
{
    [self removeTabButtons];
    [self addTabButtons];
    
    // Force redraw of the previously active tab.
    NSUInteger lastIndex = self.selectedIndex;
    _selectedIndex = NSNotFound;
    self.selectedIndex = lastIndex;
}

- (void)layoutTabButtons
{
    NSUInteger count = [self.items count];
    CGRect remainingButtonsRect = self.view.bounds;
    CGFloat buttonWidth = CGRectGetWidth(remainingButtonsRect)/count;

    for (UIButton *button in [self.view subviews])
    {
        CGRect buttonRect;
        CGRectDivide(remainingButtonsRect, &buttonRect, &remainingButtonsRect, buttonWidth, CGRectMinXEdge);
        button.frame = buttonRect;
    }
}

#pragma mark - Managing selections

- (void)deselectTabButton:(UIButton *)button atIndex:(NSUInteger)index
{
    button.selected = NO;
}

- (void)selectTabButton:(UIButton *)button atIndex:(NSUInteger)index
{
    button.selected = YES;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    if (selectedIndex == NSNotFound)
    {
        selectedIndex = 0;
    }

    if ([self.delegate respondsToSelector:@selector(tabularController:shouldSelectItem:atIndex:)])
    {
        DQTabularItem *item = self.items[selectedIndex];
        if( ! [self.delegate tabularController:self shouldSelectItem:item atIndex:selectedIndex])
            return;
    }

    if ( ! [self isViewLoaded])
    {
        [self willChangeValueForKey:@"selectedIndex"];
        _selectedIndex = selectedIndex;
        [self didChangeValueForKey:@"selectedIndex"];
    }
    else if (_selectedIndex != selectedIndex)
    {
        DQTabularItem *toItem;
        DQTabularItem *fromItem;

        if (_selectedIndex != NSNotFound)
        {
            UIButton *fromButton = (UIButton *)[self.view viewWithTag:(NSInteger)(DQTabularControllerButtonTagOffset + _selectedIndex)];
            [self deselectTabButton:fromButton atIndex:_selectedIndex];
            fromItem = self.selectedItem;
        }

        _selectedIndex = selectedIndex;

        UIButton *toButton;
        if (_selectedIndex != NSNotFound)
        {
            toButton = (UIButton *)[self.view viewWithTag:(NSInteger)(DQTabularControllerButtonTagOffset + _selectedIndex)];
            [self selectTabButton:toButton atIndex:_selectedIndex];
            toItem = self.selectedItem;
        }

        if ([fromItem viewController] != nil)
        {
            [self.delegate tabularController:self hideViewController:fromItem.viewController];
        }
        if ([toItem viewController] != nil)
        {
            [self.delegate tabularController:self displayViewController:toItem.viewController];
        }
        if (toItem != nil)
        {
            if ([self.delegate respondsToSelector:@selector(tabularController:didSelectItem:atIndex:)])
            {
                [self.delegate tabularController:self didSelectItem:toItem atIndex:selectedIndex];
            }
        }
    }
}

- (void)setSelectedItem:(DQTabularItem *)item
{
    NSUInteger index = [self.items indexOfObject:item];
    if (index != NSNotFound)
        [self setSelectedIndex:index];
}

#pragma mark - Actions

- (void)tabButtonSelected:(UIButton *)sender
{
    NSInteger index = sender.tag - DQTabularControllerButtonTagOffset;
    [self setSelectedIndex:(NSUInteger)index];
}

#pragma mark - Accessors

- (DQTabularItem *)selectedItem
{
    if (self.selectedIndex != NSNotFound)
        return self.items[self.selectedIndex];
    return nil;
}

- (DQTabularItem *)itemForIndex:(NSUInteger)index
{
    return [self.items objectAtIndex:index];
}

#pragma mark - Private helpers

- (CGFloat)borderSpacing
{
    return 20.0f;
}

- (CGPoint)_originForButtonAtIndex:(NSUInteger)index
{
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    return (CGPoint){ .x = viewWidth, .y = self.borderSpacing };
}

- (UIButton *)_buttonForItem:(DQTabularItem *)item atIndex:(NSUInteger)index
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, DQTabularControllerButtonWidth, CGRectGetHeight(self.view.bounds));
    button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [button addTarget:self action:@selector(tabButtonSelected:) forControlEvents:UIControlEventTouchUpInside];

    [button setBackgroundImage:[self _imageForButtonAtIndex:index hit:NO] forState:UIControlStateNormal];
    UIImage *selectedImage = [self _imageForButtonAtIndex:index hit:YES];
    [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [button setBackgroundImage:selectedImage forState:UIControlStateSelected];

    UIImage *image = [self.items[index] compositeImage];
    [button setImage:image forState:UIControlStateNormal];
    button.tag = DQTabularControllerButtonTagOffset + index;
    return button;
}

- (UIImage *)_imageForButtonAtIndex:(NSUInteger)index hit:(BOOL)hit
{
    NSMutableString *imageName = [@"modal_tab_" mutableCopy];
    if(index == 0)
        [imageName appendString:@"left"];
    else if (index == [self.items count] - 1)
        [imageName appendString:@"right"];
    else
        [imageName appendString:@"center"];

    if (hit)
        [imageName appendString:@"_hit"];

    return [[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(11.0f, 11.0f, 12.0, 12.0)];
}

@end
