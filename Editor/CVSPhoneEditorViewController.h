//
//  CVSPhoneEditorViewController.h
//  DrawQuest
//
//  Created by David Mauro on 9/11/13.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import "CVSEditorViewController.h"

@interface CVSPhoneEditorViewController : CVSEditorViewController

@property (nonatomic, copy) void (^didRotateDeviceBlock)(CVSPhoneEditorViewController *vc);

@end
