//
//  UIImage+Operation.h
//  Qditor_iOS
//
//  Created by kimks on 3/27/14.
//  Copyright (c) 2014 scn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Operation)

- (UIImage *)resizedImage:(CGSize)size;

- (UIImage *)resizedImage:(CGFloat)width height:(CGFloat)height;

- (UIImage *)rotationImage:(NSInteger)rotation;

- (UIImage *)thumbnail;

- (void)getDataToContext:(CGContextRef)context;

+ (UIImage *)imageNamedForPhone:(NSString *)name;

+ (UIImage *)imageWithColor:(UIColor *)color;

+ (UIImage *)imageWithCGImage:(CGImageRef)image croppedToSize:(CGSize)size;

+ (UIImage *)croppedImageWithImage:(UIImage *)image zoom:(CGFloat)zoom;
@end
