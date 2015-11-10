//
//  DQColorPaletteTableViewCell.h
//  DrawQuest
//
//  Created by Phillip Bowden on 11/1/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DQColorPaletteView;
@class DQColorPaletteTableViewCell;

@protocol DQColorPaletteTableViewCellDelegate <NSObject>

- (void)colorPaletteTableViewCell:(DQColorPaletteTableViewCell *)cell purchaseButtonTapped:(UIButton *)purchaseButton;

@end

@interface DQColorPaletteTableViewCell : UITableViewCell

@property (nonatomic, weak) id<DQColorPaletteTableViewCellDelegate> delegate;

// designated initializer
- (id)initWithDelegate:(id<DQColorPaletteTableViewCellDelegate>)delegate reuseIdentifier:(NSString *)reuseIdentifier;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier MSDesignatedInitializer(initWithDelegate:reuseIdentifier:);
- (id)initWithFrame:(CGRect)frame MSDesignatedInitializer(initWithDelegate:reuseIdentifier:);
- (id)init MSDesignatedInitializer(initWithDelegate:reuseIdentifier:);

- (void)setTitle:(NSString *)title saleText:(NSString *)saleText colors:(NSArray *)colors purchaseCost:(NSString *)costString purchased:(BOOL)purchased;

@end
