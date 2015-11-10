//
//  UIColor+STAdditions.m
//
//  Created by Buzz Andersen on 4/5/11.
//  Copyright 2012 System of Touch. All rights reserved.
//

#import "UIColor+STAdditions.h"
#import "STUtils.h"


@implementation UIColor (STAdditions)

STCachedColor(groupTableViewBorderColor, 168.0f, 171.0f, 174.0f, 1.0f);
STCachedColor(tableCellEditableTextColor, 50.0f, 79.0f, 133.0f, 1.0f);

STCachedColor(overlayBackgroundColor, 0.0f, 0.0f, 0.0f, 0.5f);

STCachedColor(tokenFieldCompletionTableBackgroundColor, 235.0f, 235.0f, 235.0f, 1.0f);
STCachedGrayscaleColor(tokenFieldPromptLabelTextColor, 0.5f, 1.0f);
STCachedGrayscaleColor(tokenFieldCompletionTableSeparatorColor, 0.7f, 1.0f);
STCachedGrayscaleColor(tokenFieldCompletionTableCellSeparatorColor, 0.85f, 1.0f);

STCachedColor(itemCountCapsuleColor, 140.0f, 153.0f, 181.0f, 1.0f);
STCachedGrayscaleColor(itemCountCapsuleHighlightedColor, 1.0f, 1.0f);
STCachedGrayscaleColor(itemCountCapsuleTextColor, 1.0f, 1.0f);
STCachedColor(itemCountCapsuleHighlightedTextColor, 30.0f, 91.0, 232.0, 1.0f);

STCachedColor(selectionListSelectedTextColor, 56.0, 84.0, 135.0, 1.0);
STCachedGrayscaleColor(selectionListNormalTextColor, 0.0, 1.0);

@end
