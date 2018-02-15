//
//  GLView.h
//  transit_img
//
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "GPUImageContext.h"

@interface GLView : UIView
{
    
}

@property(readonly, nonatomic) CGSize sizeInPixels;

- (void) cleanFBO;
- (void)initAll;
-(void)resetAll;
- (void)clearScreen;
- (void)setExportEnable:(bool)enable;
- (void)DrawImageWithDistortion:(TextureInfo*)texInfo Mode:(int)mode Distortion:(CGFloat)distortion Zoom:(CGFloat)zoomScale;
-(void) applyDistortion:(int)modeIndex Distortion:(CGFloat)distortion Zoom:(CGFloat)zoomScale Texture:(TextureInfo*)texInfo;

- (void)InitPrograms;
- (void)SetFBOSizeForExport:(int)nWidth Height:(int)nHeight;
- (CVPixelBufferRef) getPixelBuffer;

@end

extern GLView *gGLView;

