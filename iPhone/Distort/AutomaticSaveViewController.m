//
//  AutomaticSaveViewController.m
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "AutomaticSaveViewController.h"
#import "AutomaticCameraViewController.h"
#import "AutomaticMainController.h"
#import "distortion.h"

@interface AutomaticSaveViewController ()
{
    NSInteger selectedCount;
    UIView *waitView;

}
@property (strong, nonatomic) IBOutlet UILabel *savedLabel;

@end

@implementation AutomaticSaveViewController
@synthesize savedLabel;

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
    waitView = [[UIView alloc] initWithFrame:self.view.frame];
    UIActivityIndicatorView * indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    [indicatorView startAnimating];
    [indicatorView setCenter:self.view.center];
    [waitView addSubview:indicatorView];
    [waitView setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:0.3]];
    [self.view addSubview:waitView];
    waitView.hidden = YES;
    savedLabel.hidden = YES;
    
    /* Apply distortion profile. */

    NSArray *array = self.navigationController.viewControllers;
    AutomaticMainController * mainController = nil;
    AutomaticCameraViewController *cameraController = nil;
    
    if(!array)
        return;
    for(int i = 0; i <array.count; i++)
    {
        if([[array objectAtIndex:i] isKindOfClass:[AutomaticMainController class]])
            mainController = [array objectAtIndex:i];
        else if([[array objectAtIndex:i] isKindOfClass:[AutomaticCameraViewController class]])
            cameraController = [array objectAtIndex:i];
    }
    
    if(mainController)
    {
        selectedCount = [mainController getSelectedCount];
        [self ShowWaitIndicator:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [mainController applyDistortion:[cameraController getDistortionMode] Distortion:1.f Zoom:1.f completionHandler:^{
                selectedCount--;
                if(selectedCount == 0)
                {
                    NSLog(@"All done!");
                    [self ShowWaitIndicator:NO];
                    NSString *str = savedLabel.text;
                    savedLabel.text = [NSString stringWithFormat:str, PHOTO_ALBUM_NAME];
                    savedLabel.hidden = NO;
                }
            }];
        });
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    self.savedLabel.hidden = YES;
}

- (void) viewDidAppear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
    savedLabel.hidden = YES;
}

-(void)ShowWaitIndicator:(BOOL)isShow
{
    waitView.hidden = !isShow;
}

- (IBAction)touchNew:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (IBAction)touchBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
