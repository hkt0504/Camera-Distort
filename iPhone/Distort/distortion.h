//
//  distortion.h
//  curbe_img
//
//  Created by Michel Han on 8/26/14.
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#ifndef __curbe_img__distortion__
#define __curbe_img__distortion__

typedef struct distortion_param
{
    const char *name;
    double focalLengthX;
    double focalLengthY;
    double centerX;
    double centerY;
    double distortionParam1;
    double distortionParam2;
    double residualMeanError;
    double residualStandardDeviation;
    double m1;
    double m2;
    double m3;
    double m4;
}distortion_param_t;

typedef struct coefficient_param
{
    double delta1;
    double delta2;
    double delta3;
    double delta4;
    double c1;
    double c2;
    double c3;
    double c4;
}coefficient_param_t;

enum DISTORTION_MODE
{
    DISTORTION_HERO3_BLACK = 0,
    DISTORTION_HERO3_SILVER,
    DISTORTION_HERO3_WHITE,
    DISTORTION_HERO3PLUS_BLACK,
    DISTORTION_MAX,
};

#define DISTORTION_VALUE_MIN        0.0
#define DISTORTION_VALUE_MAX        2.0
#define DISTORTION_VALUE_DEFAULT    1.0

#define ZOOM_VALUE_MIN      0.0
#define ZOOM_VALUE_MAX      2.0
#define ZOOM_VALUE_DEFAULT  1.0

#define PHOTO_ALBUM_NAME    "Distortion"

#ifdef __cplusplus
extern "C"
{
#endif

int get_camera_width();
int get_camera_height();
void set_image_size(int width, int height);
const char* get_distortion_profile_name(unsigned int mode);
distortion_param_t get_distortion_profile(int mode);
coefficient_param_t get_coefficient_profile(int mode);
void distort_init(unsigned int mode, double val);   
void distort(Byte *srcImg, Byte* dstImg, int srcWidth, int srcHeight, int colorDepth);
CGImageRef createImageFromDistortionData(Byte* dstImageData, int width, int height);
void createContextWithCamera(CGImageRef imageRef, Byte* orgImageData);
CGImageRef applyDistortionToImage(CGImageRef orgImage, Byte* orgData, Byte* dstData, float zoom);

#ifdef __cplusplus
};
#endif
#endif /* defined(__curbe_img__distortion__) */
