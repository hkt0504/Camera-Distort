//
//  ManualMainController.h
//  Distort
//
//  Created by Michel Han on 8/27/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ManualMainController : UIViewController<UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UISlider *distortionSlider;
@property (strong, nonatomic) IBOutlet UISlider *zoomSlider;
@property (strong, nonatomic) IBOutlet UIPickerView *modePickerView;
- (IBAction)touchDistortion:(id)sender;
- (IBAction)touchZoom:(id)sender;

- (void)setNewImage:(CGImageRef)imageRef;
- (void) initDistortion;
- (BOOL)applyDistortion:(BOOL)isSave Mode:(int)mode Distortion:(float)distortion Zoom:(float)zoom completionHandler:(void (^)(void))handler;
- (void)applySave:(void (^)(void))handler;
@end
