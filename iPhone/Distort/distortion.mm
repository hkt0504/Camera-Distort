//
//  distortion.mm
//  curbe_img
//
//  Created by Michel Han on 8/26/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#include "distortion.h"

#define DEFAULT_WIDTH   1000
#define DEFAULT_HEIGHT  1000
double g_camera_width = DEFAULT_WIDTH;
double g_camera_height = DEFAULT_HEIGHT;

distortion_param_t g_distortion_profiles[] = {
    {"HERO3 BLACK",    0.328738,   0.328738,   0.498845,   0.477573,   0.412,      0.515,      0.76,      0.895,     0.06,   0,         -0.07,  0},
    {"HERO3 SILVER",   0.385529,   0.385529,   0.491823,   0.48287,    0.494,      0.595,      0.8,       0.895,     0.067,  -0.002,    -0.102, 0.025},
    {"HERO3 WHITE",    0.507263,   0.507263,   0.51005,    0.502709,   0.75,       0.895,      0.97,      1.1,       0.153,  -0.038,    -0.16,  0.09},
    {"HERO3+ BLACK",   0.452423,   0.452423,   0.500806,   0.502232,   0.59,       0.725,      0.96,      1.06,      0.13,   -0.02,     -0.175, 0.055},
    {0},
};

coefficient_param_t g_coefficient_profiles[] = {
    {0.055,     -0.02,  -0.026,     0.063,      0.118,      0.215,      0.01,     0.165},
    {0.093,     -0.018, -0.052,     0.085,      0.037,      0.135,      0.03,     0.165},
    {0.232,     -0.062, -0.112,     0.173,      0.037,      0.205,      0.07,     0.26},
    {0.125,     -0.05,  -0.057,     0.108,      0.107,      0.255,      0.04,     -0.01},
    {0},
};

static unsigned int g_distortion_mode =  DISTORTION_HERO3_BLACK;
static double g_distortion_val = 1;

const char* get_distortion_profile_name(unsigned int mode)
{
    return g_distortion_profiles[mode].name;
}

distortion_param_t get_distortion_profile(int mode)
{
    return g_distortion_profiles[mode];
}

coefficient_param_t get_coefficient_profile(int mode)
{
    return g_coefficient_profiles[mode];
}

void distort_init(unsigned int mode, double val)
{
    if(mode < DISTORTION_MAX)
        g_distortion_mode = mode;
    
    g_distortion_val = val;
}

int get_camera_width()
{
    return g_camera_width;
}

int get_camera_height()
{
    return g_camera_height;
}

void set_image_size(int width, int height)
{
    g_camera_width = width;
    g_camera_height = height;
}

//convert to camera coordinate
void Normalize(distortion_param_t param, double &x, double& y)
{
	double y_n = (y - param.centerY) / param.focalLengthY;
	double x_n = (x - param.centerX) / param.focalLengthX;
    
	x = x_n;
	y = y_n;
}

//pixel distort transform
void Distort(distortion_param_t param, double& x, double& y)
{
	double r2 = x * x + y * y;
	double radial_d = 1 + param.distortionParam1 * r2 + param.distortionParam2 * r2 * r2;
	double x_d = radial_d * x + 2 * param.residualMeanError * x * y + param.residualStandardDeviation * (r2 + 2 * x * x);
	double y_d = radial_d * y + param.residualMeanError * (r2 + 2 * y * y) + 2 * param.residualStandardDeviation * x * y;
    
	x = x_d;
	y = y_d;
}

//convert to pixel coordinate
void Denormalize(distortion_param_t param, double &x, double& y)
{
	double x_p = param.focalLengthX * x + param.centerX;
	double y_p = param.focalLengthY * y + param.centerY;
    
	x = x_p;
	y = y_p;
}

//point distort transform
void DistortPixel(distortion_param_t param, int& px, int& py)
{
	double x = px;
	double y = py;
    
	Normalize(param, x, y);
	Distort(param, x, y);
	Denormalize(param, x, y);
    
	px = (int)(x + 0.5);
	py = (int)(y + 0.5);
}

//distort image
void distort(Byte *srcImg, Byte* dstImg, int srcWidth, int srcHeight, int colorDepth)
{
	int w = srcWidth;
	int h = srcHeight;
    
    distortion_param_t param;
    memcpy(&param, &g_distortion_profiles[g_distortion_mode], sizeof(distortion_param_t));
    
    param.focalLengthX = g_camera_width * param.focalLengthX;
	param.focalLengthY = g_camera_height * param.focalLengthY;
	param.centerX = g_camera_width * param.centerX;
	param.centerY = g_camera_height * param.centerY;

    param.distortionParam1 *= g_distortion_val;
    param.distortionParam2 *= g_distortion_val;
    param.residualMeanError *= g_distortion_val;
    param.residualStandardDeviation *= g_distortion_val;
    
    for(int y=0; y<h; y++)
    {
        Byte * dst = dstImg + w * colorDepth * y;
        for(int x=0; x<w; x++)
        {
            int px = x;
            int py = y;
            DistortPixel(param, px, py);
            
            if(px>=0 && py>=0 && px<w && py<h)
            {
                unsigned char * src = srcImg + w * colorDepth * py + px * colorDepth;
                
                memcpy(dst, src, colorDepth);
                dst += colorDepth;
            }
            else
            {
                memset(dst, 0, colorDepth);
                dst += colorDepth;
            }
        }
    }
}

CGImageRef createImageFromDistortionData(Byte* dstImageData, int width, int height)
{
    int nrOfColorComponents = 4; //RGBA
    int bitsPerColorComponent = 8;
    int rawImageDataLength = width * height * nrOfColorComponents;
    BOOL interpolateAndSmoothPixels = NO;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef dataProviderRef;
    CGColorSpaceRef colorSpaceRef;
    CGImageRef imageRef;
    
    @try
    {
        GLubyte *rawImageDataBuffer = dstImageData;
        
        dataProviderRef = CGDataProviderCreateWithData(NULL, rawImageDataBuffer, rawImageDataLength, nil);
        colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        imageRef = CGImageCreate(width, height, bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents, colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent);
    }
    @finally
    {
        CGDataProviderRelease(dataProviderRef);
        CGColorSpaceRelease(colorSpaceRef);
    }
    return imageRef;
}

void createContextWithCamera(CGImageRef imageRef, Byte* orgImageData)
{
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * get_camera_width();
    NSUInteger bitsPerComponent = 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = nil;
    
    context = CGBitmapContextCreate(orgImageData, get_camera_width(), get_camera_height(),
                                    bitsPerComponent, bytesPerRow, colorSpace,
                                    kCGImageAlphaPremultipliedLast);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, CGRectMake(0, 0, get_camera_width(), get_camera_height()), imageRef);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
}

CGImageRef applyDistortionToImage(CGImageRef orgImage, Byte* orgData, Byte* dstData, float zoom)
{
    int colorDepth = (int)(CGImageGetBitsPerPixel(orgImage) / 8);
    
    createContextWithCamera(orgImage, orgData);
    
    distort(orgData, dstData, g_camera_width, g_camera_height, colorDepth);
    
    CGImageRef dstImage = createImageFromDistortionData(dstData, g_camera_width, g_camera_height);
    
    if(dstImage)
    {
        if(zoom > 1.0f)
        {
            CGFloat zoomReciprocal = 1.0f / zoom;
            
            int width = (int)CGImageGetWidth(dstImage);
            int height = (int)CGImageGetHeight(dstImage);
            
            CGRect croppedRect = CGRectMake((width - width * zoomReciprocal)/ 2,
                                            (height - height * zoomReciprocal)/ 2,
                                            width * zoomReciprocal,
                                            height * zoomReciprocal);
            
            CGImageRef croppedImageRef = CGImageCreateWithImageInRect(dstImage, croppedRect);
            
            Byte *tempData = (Byte*)malloc(get_camera_width() * get_camera_height() * 4);
            memset(tempData, 0, get_camera_width() * get_camera_height() * 4);
            NSUInteger bytesPerPixel = 4;
            NSUInteger bytesPerRow = bytesPerPixel * get_camera_width();
            NSUInteger bitsPerComponent = 8;
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            
            CGContextRef context = nil;
            
            context = CGBitmapContextCreate(tempData, get_camera_width(), get_camera_height(),
                                            bitsPerComponent, bytesPerRow, colorSpace,
                                            kCGImageAlphaPremultipliedLast);
            
            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
            CGContextDrawImage(context, CGRectMake(0, 0, get_camera_width(), get_camera_height()), croppedImageRef);
            CGColorSpaceRelease(colorSpace);
            CGContextRelease(context);
            
            memcpy(dstData, tempData, get_camera_width() * get_camera_height() * 4);
            free(tempData);
        }
        else
        {
            CGFloat zoomReciprocal = zoom / 1.0f;
            
            int width = (int)CGImageGetWidth(dstImage);
            int height = (int)CGImageGetHeight(dstImage);
            
            CGRect croppedRect = CGRectMake((width - width * zoomReciprocal)/ 2,
                                            (height - height * zoomReciprocal)/ 2,
                                            width * zoomReciprocal,
                                            height * zoomReciprocal);
            
            Byte *tempData = (Byte*)malloc(get_camera_width() * get_camera_height() * 4);
            memset(tempData, 0, get_camera_width() * get_camera_height() * 4);
            NSUInteger bytesPerPixel = 4;
            NSUInteger bytesPerRow = bytesPerPixel * get_camera_width();
            NSUInteger bitsPerComponent = 8;
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            
            CGContextRef context = nil;
            
            context = CGBitmapContextCreate(tempData, get_camera_width(), get_camera_height(),
                                            bitsPerComponent, bytesPerRow, colorSpace,
                                            kCGImageAlphaPremultipliedLast);
            
            CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
            CGContextDrawImage(context, croppedRect, dstImage);
            CGColorSpaceRelease(colorSpace);
            CGContextRelease(context);
            
            memcpy(dstData, tempData, get_camera_width() * get_camera_height() * 4);
            free(tempData);

        }
    }
    return dstImage;
}
