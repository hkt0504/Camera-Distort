//
//  AutomaticMainController.m
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "AutomaticMainController.h"
#import "AlbumTableViewController.h"
#import "AutomaticCameraViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import "PhotoCell.h"
#import "ManualMainController.h"
#import "distortion.h"
#import "GLView.h"
#import "GPUImageContext.h"

@interface AutomaticMainController ()
{
    NSMutableArray *assetList;
    NSMutableArray *selectedList;
    TextureInfo *orgImageInfo;
    AlbumTableViewController *albumController;
    NSString *albumName;
}
@end

@implementation AutomaticMainController

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) selectedAlbum:(NSString *)name
{
    if(albumName != name)
    {
        [assetList removeAllObjects];
        [self.collectionView reloadData];
    }
    
    albumName = name;
}

- (void) viewDidAppear:(BOOL)animated
{
    if(assetList)
        [assetList removeAllObjects];
    else
        assetList = [[NSMutableArray alloc] init];
    
    if(selectedList)
       [selectedList removeAllObjects];
    else
        selectedList = [[NSMutableArray alloc] init];
    
    ALAssetsLibrary *library = [AutomaticMainController defaultAssetsLibrary] ;
	
	[library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            if(albumName && ![albumName isEqualToString:[group valueForProperty:ALAssetsGroupPropertyName]])
                return;

            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset) {
                    [assetList addObject:asset];
                }
            }];
        }
        else
        {
            NSLog(@"Done! Count = %lu", (unsigned long)assetList.count);
            [self.collectionView reloadData];
        }
	}
    failureBlock:^(NSError *error) {
        NSLog(@"error enumerating AssetLibrary groups %@\n", error);
    }];
    
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    orgImageInfo = [[ TextureInfo alloc] init];
    albumController = nil;
    albumName = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)touchNext:(id)sender {
    if(selectedList.count)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AutomaticCameraViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
        
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return assetList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell *cell = (PhotoCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoCell" forIndexPath:indexPath];
    
    BOOL isCellSelected = [selectedList containsObject:assetList[assetList.count - indexPath.row - 1]];
    if(!isCellSelected)
    {
        if(cell.selected)
           [cell setSelected:NO];
        [cell.photoImageView setAlpha:1.0f];
    }
    else
    {
        if(!cell.selected)
            [cell setSelected:YES];
        [cell.photoImageView setAlpha:0.5f];
    }

    ALAsset *asset = assetList[indexPath.row];
    cell.asset = asset;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCell* cell = (PhotoCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    if(cell.selected)
    {
        [selectedList addObject:assetList[assetList.count - indexPath.row - 1]];
        [cell.photoImageView setAlpha:0.5f];
    }
    else
    {
        [selectedList removeObject:assetList[assetList.count - indexPath.row - 1]];
        [cell.photoImageView setAlpha:1.0f];
    }
}
- (IBAction)touchAlbums:(id)sender {
    if(!albumController)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        albumController = [storyboard instantiateViewControllerWithIdentifier:@"AlbumController"];
        albumController.delegate = self;
    }

    [self.navigationController pushViewController:albumController animated:YES];
}

- (NSInteger) getSelectedCount
{
    return selectedList.count;
}

- (BOOL)applyDistortion:(int)mode Distortion:(float)distortion Zoom:(float)zoom completionHandler:(void (^)(void))handler
{
    NSLog(@"distortion(%f), zoom(%f)", distortion, zoom);
    CGImageRef imageRef;
    
    NSString *albumName = [NSString stringWithFormat:@"%s", PHOTO_ALBUM_NAME];
    ALAssetsLibrary *library = [AutomaticMainController defaultAssetsLibrary];

    CGImageRef dstImage = nil;
    if(!selectedList.count && handler)
    {
        handler();
        return YES;
    }

    for (int i = 0; i < selectedList.count; i++)
    {
        ALAsset *asset = selectedList[i];
        ALAssetRepresentation *representation = [asset defaultRepresentation];
        
        if(representation)
        {
            imageRef = [representation fullResolutionImage];
        }
        else
            continue;

        if(!imageRef)
            continue;
        
        if(orgImageInfo)
           [orgImageInfo unloadTexture];
        
        [GPUImageContext loadTextureFromImage:imageRef TextureInfo:orgImageInfo];
        [gGLView SetFBOSizeForExport:orgImageInfo.width Height:orgImageInfo.height];
        
        CVPixelBufferRef pxbuffer = nil;
        
        if(![GPUImageContext supportsFastTextureUpload])
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
        
        [gGLView DrawImageWithDistortion:orgImageInfo Mode:mode Distortion:distortion Zoom:zoom];
        
        Byte *pixelBufferData = nil;
        
        if ([GPUImageContext supportsFastTextureUpload])
        {
            pxbuffer = [gGLView getPixelBuffer];
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
@end
