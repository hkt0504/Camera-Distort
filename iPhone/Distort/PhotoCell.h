//
//  PhotoCell.h
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoCell : UICollectionViewCell
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@property(nonatomic, strong) ALAsset *asset;
@end
