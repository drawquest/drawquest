//
//  CVSDebugConsoleViewController.m
//  Editor
//
//  Created by Phillip Bowden on 10/8/12.
//  Copyright (c) 2012 Canvas. All rights reserved.
//

#import "CVSDebugConsoleViewController.h"

#import "CVSDrawingTypes.h"

@interface CVSDebugConsoleViewController ()

@property CVSBrushType selectedBrushType;
@property CVSBrushAttributes *selectedBrush;

@property (strong, nonatomic) IBOutlet UISlider *lineWidthSlider;
@property (strong, nonatomic) IBOutlet UISlider *opacitySlider;
@property (strong, nonatomic) IBOutlet UISegmentedControl *lineJoinControl;
@property (strong, nonatomic) IBOutlet UISegmentedControl *lineCapControl;

@property (strong, nonatomic) IBOutlet UILabel *lineWidthLabel;
@property (strong, nonatomic) IBOutlet UILabel *opacityLabel;

@property (strong, nonatomic) NSArray *lineJoins;
@property (strong, nonatomic) NSArray *lineCaps;

@end

@implementation CVSDebugConsoleViewController

- (id)init
{
    self = [super initWithNibName:@"CVSDebugConsoleView" bundle:nil];
    if (!self) {
        return nil;
    }
    
    _lineCaps = @[@(kCGLineCapRound), @(kCGLineCapButt), @(kCGLineCapSquare)];
    _lineJoins = @[@(kCGLineJoinRound), @(kCGLineJoinMiter), @(kCGLineJoinBevel)];
    
    self.selectedBrushType = CVSBrushTypePen;
    self.selectedBrush = CVSBrushAttributesReferenceForBrushType(self.selectedBrushType);
    
    return self;
}


- (void)viewDidAppear:(BOOL)animated
{
    [self updateInterfaceForBrushType:CVSBrushTypePen];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)updateInterfaceForBrushType:(CVSBrushType)brushType
{
    CVSBrushAttributes brush = CVSBrushAttributesForBrushType(brushType);
    
    self.lineWidthSlider.value = brush.lineWidth;
    self.lineWidthLabel.text = [NSString stringWithFormat:@"%.2f", brush.lineWidth];
    self.opacitySlider.value = brush.alpha;
    self.opacityLabel.text = [NSString stringWithFormat:@"%.2f", brush.alpha];

    NSUInteger lineJoinIndex = [self.lineJoins indexOfObject:@(brush.lineJoin)];
    self.lineJoinControl.selectedSegmentIndex = lineJoinIndex;
    
    NSUInteger lineCapIndex = [self.lineCaps indexOfObject:@(brush.lineCap)];
    self.lineCapControl.selectedSegmentIndex = lineCapIndex;
}

#pragma mark - Actions

- (IBAction)hideDebugConsole:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)selectedToolChanged:(id)sender
{
    UISegmentedControl *control = (UISegmentedControl *)sender;
    self.selectedBrushType = control.selectedSegmentIndex + 1;
    self.selectedBrush = CVSBrushAttributesReferenceForBrushType(self.selectedBrushType);
    [self updateInterfaceForBrushType:self.selectedBrushType];
}

- (IBAction)lineWidthChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    self.lineWidthLabel.text = [NSString stringWithFormat:@"%.2f", slider.value];
    self.selectedBrush->lineWidth = (CGFloat)slider.value;
}

- (IBAction)opacityChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    self.opacityLabel.text = [NSString stringWithFormat:@"%.2f", slider.value];
    self.selectedBrush->alpha = (CGFloat)slider.value;
}

- (IBAction)lineCapChanged:(id)sender
{
    UISegmentedControl *control = (UISegmentedControl *)sender;
    CGLineCap lineCap = [[self.lineCaps objectAtIndex:control.selectedSegmentIndex] integerValue];
    self.selectedBrush->lineCap = lineCap;
}

- (IBAction)lineJoinChanged:(id)sender
{
    UISegmentedControl *control = (UISegmentedControl *)sender;
    CGLineJoin lineJoin = [[self.lineJoins objectAtIndex:control.selectedSegmentIndex] integerValue];
    self.selectedBrush->lineJoin = lineJoin;
}

@end
