//
//  UIImage+Operation.m
//  Qditor_iOS
//
//  Created by kimks on 3/27/14.
//  Copyright (c) 2014 scn. All rights reserved.
//

#import "UIImage+Operation.h"
#import <AVFoundation/AVFoundation.h>

#define THUMB_WIDTH 120
#define THUMB_HEIGHT 90

@implementation UIImage (Operation)

- (UIImage *)resizedImage:(CGSize)size
{
    if (CGSizeEqualToSize(size, self.size)) {
        return self;
    }

    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    else
        UIGraphicsBeginImageContext(size);
    
    [self drawInRect:(CGRect){CGPointZero, size}];
    
    // Retrieve the UIImage from the current context
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageOut;
}

- (UIImage *)resizedImage:(CGFloat)width height:(CGFloat)height
{
    return [self resizedImage:CGSizeMake(width, height)];
}

- (UIImage *)rotationImage:(NSInteger)rotation
{
    CGSize size = (rotation == 90 || rotation == 270) ? CGSizeMake(self.size.height, self.size.width) : CGSizeMake(self.size.width, self.size.height);

    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    else
        UIGraphicsBeginImageContext(size);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    switch (rotation) {
        case 0:
            CGContextTranslateCTM(context, 0.0, size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            break;
        case 90:
            CGContextTranslateCTM(context, size.width, 0.0);
            CGContextScaleCTM(context, -1.0, 1.0);
            CGContextTranslateCTM(context, size.width / 2, size.height / 2);
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, -size.height / 2, -size.width / 2);
            break;
        case 180:
            CGContextTranslateCTM(context, size.width, 0.0);
            CGContextScaleCTM(context, -1.0, 1.0);
            break;
        case 270:
            CGContextTranslateCTM(context, size.width, 0.0);
            CGContextScaleCTM(context, -1.0, 1.0);
            CGContextTranslateCTM(context, size.width / 2, size.height / 2);
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -size.height / 2, -size.width / 2);
            break;
        default:
            // error degress
            break;
    }
    
    // Draw the original image to the context
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, (CGRect) {CGPointZero, self.size}, self.CGImage);

    // Retrieve the UIImage from the current context
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    return imageOut;
}

- (UIImage *)thumbnail
{
    return [self resizedImage:THUMB_WIDTH height:THUMB_HEIGHT];
}

- (void)getDataToContext:(CGContextRef)context;
{
    CGContextSaveGState(context);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, (CGRect) {CGPointZero, self.size}, self.CGImage);
    CGContextRestoreGState(context);
}

+ (UIImage *)imageNamedForPhone:(NSString *)name
{
    if ([[UIScreen mainScreen] bounds].size.height <= 480.0) {
        return [UIImage imageNamed:name];
    } else {
        NSString *realname = [name stringByDeletingPathExtension];
        NSString *ext = [name pathExtension];
        if ([ext length] == 0) {
            return [UIImage imageNamed:[realname stringByAppendingString:@"-l"]];
        } else {
            return [UIImage imageNamed:[NSString stringWithFormat:@"%@-l.%@", realname, ext]];
        }
    }
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)imageWithCGImage:(CGImageRef)image croppedToSize:(CGSize)size
{
	UIImage *thumbUIImage = nil;
	
	CGRect thumbRect = CGRectMake(0.0, 0.0, CGImageGetWidth(image), CGImageGetHeight(image));
	CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(size, thumbRect);
	cropRect.origin.x = round(cropRect.origin.x);
	cropRect.origin.y = round(cropRect.origin.y);
	cropRect = CGRectIntegral(cropRect);
	CGImageRef croppedThumbImage = CGImageCreateWithImageInRect(image, cropRect);
	thumbUIImage = [[UIImage alloc] initWithCGImage:croppedThumbImage];
	CGImageRelease(croppedThumbImage);
	
	return thumbUIImage;
}

+ (UIImage *)croppedImageWithImage:(UIImage *)image zoom:(CGFloat)zoom
{
    UIImage *croppedImage = nil;
    
    if(zoom >= 1.0f)
    {
        CGFloat zoomReciprocal = 1.0f / zoom;
        
        CGRect croppedRect = CGRectMake((image.size.width - image.size.width * zoomReciprocal)/ 2,
                                        (image.size.height - image.size.height * zoomReciprocal)/ 2,
                                        image.size.width * zoomReciprocal,
                                        image.size.height * zoomReciprocal);
        
        CGImageRef croppedImageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
        croppedImage = [[UIImage alloc] initWithCGImage:croppedImageRef scale:[image scale] orientation:[image imageOrientation]];
        NSLog(@"cropped image size (%f - %f)", croppedImage.size.width, croppedImage.size.height);
        CGImageRelease(croppedImageRef);
    }
    else
    {
        croppedImage = [UIImage imageWithCGImage:image.CGImage scale:zoom orientation:image.imageOrientation];
    }
    return croppedImage;
}


@end
