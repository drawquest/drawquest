//
//  DQBioEditorViewController.h
//  DrawQuest
//
//  Created by Jim Roepcke on 2013-11-03.
//  Copyright (c) 2013 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DQBioEditorViewController : UIViewController

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) dispatch_block_t keyboardDoneTappedBlock;

@end
