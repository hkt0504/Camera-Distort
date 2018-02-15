//
//  AutomaticCameraViewController.m
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "AutomaticCameraViewController.h"
#import "distortion.h"

@interface AutomaticCameraViewController ()
{
    unsigned int distortionMode;
}
@property (strong, nonatomic) IBOutlet UIPickerView *modePickerView;
@end

@implementation AutomaticCameraViewController
@synthesize modePickerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touchBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (int) getDistortionMode
{
    return distortionMode;
}

#pragma mark - UIPickerViewDelegate

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    const char* name = get_distortion_profile_name((int)row);
    NSString *nameStr = [NSString stringWithFormat:@"%s", name];
    
    return nameStr;
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return DISTORTION_MAX;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    distortionMode = (int)[modePickerView selectedRowInComponent:0];
}

@end
