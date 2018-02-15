//
//  ManualMainController.m
//  Distort
//
//  Created by Michel Han on 8/27/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "ManualMainController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage+Operation.h"
#import "distortion.h"
#import "ManualPhotoViewController.h"
#import "GLView.h"
#import "GPUImageContext.h"

@interface ManualMainController ()
{
    NSURL *imageURL;
    TextureInfo *orgImageInfo;
    
    IBOutlet GLView *glView;
}
@end

@implementation ManualMainController
@synthesize zoomSlider, distortionSlider, modePickerView;
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
    
    NSString *albumName = [NSString stringWithFormat:@"%s", PHOTO_ALBUM_NAME];
    ALAssetsLibrary *library = [ManualPhotoViewController defaultAssetsLibrary];
    
    [library addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group)
     {
         //How to get the album URL?
         __block ALAssetsGroup* groupToAddTo;
         ALAssetsLibrary *library = [ManualPhotoViewController defaultAssetsLibrary];
         
         [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        groupToAddTo = group;
                                    }
                                }
                              failureBlock:^(NSError* error) {
                              }];
     } failureBlock:^(NSError *error) {
         //Handle the error
     }];
    
    imageURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"default_background.jpg"];
    
    [distortionSlider setMinimumValue:DISTORTION_VALUE_MIN];
    [distortionSlider setMaximumValue:DISTORTION_VALUE_MAX];
    distortionSlider.value = DISTORTION_VALUE_DEFAULT;
    
    [zoomSlider setMinimumValue:ZOOM_VALUE_MIN];
    [zoomSlider setMaximumValue:ZOOM_VALUE_MAX];
    zoomSlider.value = ZOOM_VALUE_DEFAULT;
    
    orgImageInfo = [[ TextureInfo alloc] init];
    
    [self loadImage:imageURL];
    gGLView = glView;
}

- (void) initDistortion
{
    distortionSlider.value = DISTORTION_VALUE_DEFAULT;
    zoomSlider.value = ZOOM_VALUE_DEFAULT;
    [modePickerView selectRow:DISTORTION_HERO3_BLACK inComponent:0 animated:NO];
    
    [self loadImage:imageURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self applyDistortion:NO Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:nil];
}

- (void)setNewImage:(CGImageRef)imageRef
{
    if(orgImageInfo)
        [orgImageInfo unloadTexture];
    
    [GPUImageContext loadTextureFromImage:imageRef TextureInfo:orgImageInfo];
}

- (BOOL)applyDistortion:(BOOL)isSave Mode:(int)mode Distortion:(float)distortion Zoom:(float)zoom completionHandler:(void (^)(void))handler
{
    if( zoom < 1.0f)
    {
        zoom = 0.5f + (zoom / 2);
    }
    NSLog(@"distortion(%f), zoom(%f)", distortion, zoom);
    
    if(!orgImageInfo.texture)
        return NO;
    
    if(isSave)
       [glView SetFBOSizeForExport:orgImageInfo.width Height:orgImageInfo.height];
    else
        [glView setExportEnable:NO];

    CVPixelBufferRef pxbuffer = nil;

    if(isSave && ![GPUImageContext supportsFastTextureUpload])
    {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                                 [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
                                 nil];
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                              orgImageInfo.width,
                                              orgImageInfo.height,
                                              kCVPixelFormatType_32BGRA,
                                              (__bridge CFDictionaryRef)options,
                                              &pxbuffer);
        
        if ((pxbuffer == NULL) || (status != kCVReturnSuccess))
            NSLog(@"OnVideoExportThreadProc:: CVPixelBufferCreate error ");
        
    }
    
    [glView DrawImageWithDistortion:orgImageInfo Mode:mode Distortion:distortion Zoom:zoom];
    
    if(isSave)
    {
        Byte *pixelBufferData = nil;
        CGImageRef dstImage = nil;
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            pxbuffer = [glView getPixelBuffer];
            if(pxbuffer)
            {
                CVPixelBufferLockBaseAddress(pxbuffer, 0);
                
                pixelBufferData = (GLubyte *)CVPixelBufferGetBaseAddress(pxbuffer);
                
                dstImage = createImageFromDistortionData(pixelBufferData, orgImageInfo.width, orgImageInfo.height);
            }
        }
        else
        {
            pixelBufferData = malloc(orgImageInfo.width * orgImageInfo.height * 4);
            memset(pixelBufferData, 0, orgImageInfo.width * orgImageInfo.height * 4);
            
            glReadPixels(0, 0, orgImageInfo.width, orgImageInfo.height, GL_RGBA, GL_UNSIGNED_BYTE, pixelBufferData);
            
            dstImage = createImageFromDistortionData(pixelBufferData, orgImageInfo.width, orgImageInfo.height);
        }
        
        if(dstImage)
        {
            __block ALAssetsGroup* groupToAddTo;
            ALAssetsLibrary *library = [ManualPhotoViewController defaultAssetsLibrary];
            NSString *albumName = [NSString stringWithFormat:@"%s", PHOTO_ALBUM_NAME];
            
            [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                   usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                       if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                           groupToAddTo = group;
                                       }
                                   }
                                 failureBlock:^(NSError* error) {
                                 }];
            [library writeImageToSavedPhotosAlbum:dstImage
                                         metadata:nil
                                  completionBlock:^(NSURL* assetURL, NSError* error) {
                                      if (error.code == 0) {
                                          
                                          // try to get the asset
                                          [library assetForURL:assetURL
                                                   resultBlock:^(ALAsset *asset) {
                                                       // assign the photo to the album
                                                       BOOL ret = [groupToAddTo addAsset:asset];
                                                       NSLog(@"add asset ret(%d)", ret);
                                                       if ([GPUImageContext supportsFastTextureUpload])
                                                           free(pixelBufferData);

                                                       if(handler)
                                                           handler();
                                                   }
                                                  failureBlock:^(NSError* error) {
                                                      if(handler)
                                                          handler();
                                                  }];
                                      }
                                      else {
                                          if(handler)
                                              handler();
                                      }
                                  }];
            
            CGImageRelease(dstImage);
        }
    }
    return YES;
}

- (void) loadImage:(NSURL*)url
{
    if([url.scheme isEqualToString:@"assets-library"])
    {
        ALAssetsLibrary *library = [ManualPhotoViewController defaultAssetsLibrary];
        
        ALAssetsLibraryAssetForURLResultBlock resultsBlock = ^(ALAsset *asset) {
            ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
            CGImageRef cgImage = [assetRepresentation fullResolutionImage];
            
            [GPUImageContext loadTextureFromImage:cgImage TextureInfo:orgImageInfo];
            [self applyDistortion:NO Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:nil];
        };
        
        ALAssetsLibraryAccessFailureBlock failure = ^(NSError *__strong error) {
            NSLog(@"Error retrieving asset from url: %@", error.localizedFailureReason);
        };
        
        [library assetForURL:url resultBlock:resultsBlock failureBlock:failure];
    }
    else
    {
        UIImage* img = [UIImage imageWithContentsOfFile:url.path];

        [GPUImageContext loadTextureFromImage:img.CGImage TextureInfo:orgImageInfo];
        [self applyDistortion:NO Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:nil];
    }
}


- (IBAction)touchDistortion:(id)sender {
    [self applyDistortion:NO Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:nil];
}

- (IBAction)touchZoom:(id)sender {
    [self applyDistortion:NO Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:nil];
}

- (void)applySave:(void (^)(void))handler
{
    [self applyDistortion:YES Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:handler];
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
    [self applyDistortion:NO Mode:(int)[modePickerView selectedRowInComponent:0] Distortion:distortionSlider.value Zoom:zoomSlider.value completionHandler:nil];
}

@end
