//
//  ManualSaveViewController.m
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "ManualSaveViewController.h"
#import "ManualMainController.h"

@interface ManualSaveViewController ()
{
    UIView *waitView;
}
@property (strong, nonatomic) IBOutlet UILabel *savedLabel;
@end

@implementation ManualSaveViewController
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
    ManualMainController * controller = nil;
    if(!array)
        return;
    for(int i = 0; i <array.count; i++)
    {
        if([[array objectAtIndex:i] isKindOfClass:[ManualMainController class]])
            controller = [array objectAtIndex:i];
    }
    
    if(controller)
    {
        [self ShowWaitIndicator:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [controller applySave:^{
                [self ShowWaitIndicator:NO];
                savedLabel.hidden = NO;
            }];
        });
    }

}

-(void)ShowWaitIndicator:(BOOL)isShow
{
    waitView.hidden = !isShow;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
}

- (void)viewDidDisappear:(BOOL)animated
{
    savedLabel.hidden = YES;
}

- (IBAction)touchBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)touchNew:(id)sender {
    NSArray *array = self.navigationController.viewControllers;
    ManualMainController * controller = nil;
    if(!array)
        return;
    for(int i = 0; i <array.count; i++)
    {
        if([[array objectAtIndex:i] isKindOfClass:[ManualMainController class]])
            controller = [array objectAtIndex:i];
    }
    
    if(controller)
       [controller initDistortion];
}
@end
