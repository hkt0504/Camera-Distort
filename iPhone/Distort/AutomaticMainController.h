//
//  AutomaticMainController.h
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumMessageDelegate.h"

@class ALAssetsLibrary;

@interface AutomaticMainController : UICollectionViewController<AlbumMessageDelegate>
+ (ALAssetsLibrary *)defaultAssetsLibrary;
- (BOOL)applyDistortion:(int)mode Distortion:(float)distortion Zoom:(float)zoom completionHandler:(void (^)(void))handler;
- (NSInteger) getSelectedCount;
@end
