//
//  AlbumTableViewController.h
//  Distort
//
//  Created by Michel Han on 9/10/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlbumMessageDelegate.h"

@interface AlbumTableViewController : UITableViewController<UITableViewDelegate>;
@property (nonatomic, assign)id<AlbumMessageDelegate> delegate;
@end
