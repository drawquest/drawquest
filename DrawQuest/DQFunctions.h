//
//  DQInlineFunctions.h
//  DrawQuest
//
//  Created by Jeremy Tregunna on 8/15/2013.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DQColorGreen,
    DQColorBlue,
    DQColorRed,
    DQColorGray
} DQColor;


extern BOOL DQSystemVersionAtLeast(NSString* systemVersionString);
extern UIImage *DQImageWithColor(DQColor color);
