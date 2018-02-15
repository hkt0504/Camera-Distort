//
//  AlbumMessageDelegate.h
//  Distort
//
//  Created by Michel Han on 9/10/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@protocol AlbumMessageDelegate <NSObject>
- (void)selectedAlbum:(NSString*)name;
@end
