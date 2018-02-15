//
//  PhotoCell.m
//  Distort
//
//  Created by Michel Han on 8/28/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "PhotoCell.h"

@interface PhotoCell()
@end

@implementation PhotoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) setAsset:(ALAsset *)asset
{
    // 2
    _asset = asset;
    self.photoImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:!self.selected];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
