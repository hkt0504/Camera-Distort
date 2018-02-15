//
//  ManualPhotoViewController.h
//  Distort
//
//  Created by Michel Han on 8/27/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumMessageDelegate.h"

@class ALAssetsLibrary;

@interface ManualPhotoViewController : UICollectionViewController <AlbumMessageDelegate>
+ (ALAssetsLibrary *)defaultAssetsLibrary;

@end
