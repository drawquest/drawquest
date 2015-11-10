//
//  CVSDebugConsoleViewController.h
//  Editor
//
//  Created by Phillip Bowden on 10/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVSDebugConsoleViewController : UIViewController

- (IBAction)hideDebugConsole:(id)sender;
- (IBAction)selectedToolChanged:(id)sender;
- (IBAction)lineWidthChanged:(id)sender;
- (IBAction)opacityChanged:(id)sender;
- (IBAction)lineCapChanged:(id)sender;
- (IBAction)lineJoinChanged:(id)sender;

@end
