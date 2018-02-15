//
//  GLView.m
//  transit_img
//
//  Copyright (c) 2014 Michel Han. All rights reserved.
//

#import "GLView.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GPUImageContext.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreFoundation/CoreFoundation.h>

#import "TransEffectShader.h"
#import "distortion.h"

#define GPUImageHashIdentifier #
#define GPUImageWrappedLabel(x) x
#define GPUImageEscapedHashIdentifier(a) GPUImageWrappedLabel(GPUImageHashIdentifier)a

GLView *gGLView = nil;

//----------- texture info of video, photo -------------------------//
void dataProviderReleaseCallback (void *info, const void *data, size_t size)
{
    free((void *)data);
}

@interface GLView()
{
    // FBO
    GLuint displayRenderbuffer, displayFramebuffer;
    GLuint displayRenderbuffer3, displayFramebuffer3;
    GLuint displayTexture3;
    CGSize displayTextureSize;
    
    // video
    GLProgram *videoDisplayProgram;
    GLProgram *colorSwizzlingProgram;
    GLProgram *distortionProgram;
    GLProgram *fishEyeProgram;

    // GL Manager
    GLuint curTexture;
    CGSize inputImageSize;
    CGFloat videoWidth;
    CGFloat videoHeight;
    
    bool isExport;
    
    CVPixelBufferRef renderPixelBuffer;
    GLuint movieFramebuffer;
    CVOpenGLESTextureRef renderTexture;
}

// Initialization and teardown
- (void)commonInit;

// Managing the display FBOs
- (void)createDisplayFramebuffer:(int)nWidth Height:(int)nHeight;
- (void)destroyDisplayFramebuffer;

// Handling fill mode
- (void)clearScreen;
- (void)removePrograms;

@end

@implementation GLView

#pragma mark -
#pragma mark Initialization and teardown

+ (Class)layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
    {
		return nil;
    }
    
    [self commonInit];
    
    return self;
}

-(id)initWithCoder:(NSCoder *)coder
{
	if (!(self = [super initWithCoder:coder]))
    {
        return nil;
	}
    
    [self commonInit];
    
	return self;
}

- (void)commonInit;
{
    // Set scaling to account for Retina display
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    
    self.opaque = YES;
    self.hidden = NO;
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    videoWidth = self.bounds.size.width;
    videoHeight = self.bounds.size.height;
    
    isExport = NO;
    
    [GPUImageContext useImageProcessingContext];
    
    [self createDisplayFramebuffer:videoWidth Height:videoHeight];
    [self InitPrograms];
}

- (void) InitPrograms
{
    // video
    videoDisplayProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:g_VideoVertexShaderStr fragmentShaderString:g_VideoFragmentShaderStr];
    if (!videoDisplayProgram.initialized)
    {
        [videoDisplayProgram addAttribute:@"position"];
        [videoDisplayProgram addAttribute:@"inputTextureCoordinate"];
        
        if (![videoDisplayProgram link])
        {
            videoDisplayProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    
    // Swizzling
    if ([GPUImageContext supportsFastTextureUpload])
    {
        colorSwizzlingProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
    }
    else
        colorSwizzlingProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:g_ColorSwizzlingVertexShaderStr fragmentShaderString:g_ColorSwizzlingFragmentShaderStr];
    
    if (!colorSwizzlingProgram.initialized)
    {
        [colorSwizzlingProgram addAttribute:@"position"];
        [colorSwizzlingProgram addAttribute:@"inputTextureCoordinate"];
        
        if (![colorSwizzlingProgram link])
        {
            colorSwizzlingProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    
    distortionProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:g_DistortionEffectVertexShaderStr fragmentShaderString:g_DistortionEffectFragmentShaderStr];
    if (!distortionProgram.initialized)
    {
        [distortionProgram addAttribute:@"position"];
        [distortionProgram addAttribute:@"inputTextureCoordinate1"];
        
        if (![distortionProgram link])
        {
            distortionProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    
    fishEyeProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:g_DistortionEffectVertexShaderStr fragmentShaderString:g_DistortionFishEyeEffectFragmentShaderStr];
    if (!fishEyeProgram.initialized)
    {
        [fishEyeProgram addAttribute:@"position"];
        [fishEyeProgram addAttribute:@"inputTextureCoordinate1"];
        
        if (![fishEyeProgram link])
        {
            fishEyeProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }

}

- (void)initAll
{
    [self createDisplayFramebuffer:videoWidth Height:videoHeight];
    [self InitPrograms];
}

-(void)resetAll
{
    [self destroyDisplayFramebuffer];
    [self removePrograms];
    
    [self cleanFBO];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
    
    [self destroyDisplayFramebuffer];
    [self removePrograms];
    
    [self cleanFBO];
}

- (void) removePrograms
{
    videoDisplayProgram = nil;
    colorSwizzlingProgram = nil;
}

#pragma mark -
#pragma mark Managing the display FBOs

- (void)createDisplayFramebuffer:(int)nWidth Height:(int)nHeight;
{
    [GPUImageContext useImageProcessingContext];
    
    ///////////////////////
    glGenFramebuffers(1, &displayFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
	
	glGenRenderbuffers(1, &displayRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
	
	[[[GPUImageContext sharedImageProcessingContext] context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
	
    GLint backingWidth, backingHeight;
    
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if ( (backingWidth == 0) || (backingHeight == 0) )
    {
        [self destroyDisplayFramebuffer];
        return;
    }
    
    _sizeInPixels.width = (CGFloat)backingWidth;
    _sizeInPixels.height = (CGFloat)backingHeight;
    
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
    
    
    displayTextureSize.width = (CGFloat)nWidth;
    displayTextureSize.height = (CGFloat)nHeight;
   
    //////////
	glGenFramebuffers(1, &displayFramebuffer3);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer3);
	
    glGenTextures(1, &displayTexture3);
	glBindTexture(GL_TEXTURE_2D, displayTexture3);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
	glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, nWidth, nHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, displayTexture3, 0);
    
    glGenRenderbuffers(1, &displayRenderbuffer3);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer3);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, nWidth, nHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, displayRenderbuffer3);
    //////////////
    
    
    GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %d, %d", nWidth, nHeight);
}

- (void)destroyDisplayFramebuffer;
{
    [GPUImageContext useImageProcessingContext];
    ////////
    
	if (displayRenderbuffer)
	{
		glDeleteRenderbuffers(1, &displayRenderbuffer);
		displayRenderbuffer = 0;
	}
    
    if (displayFramebuffer)
	{
		glDeleteFramebuffers(1, &displayFramebuffer);
		displayFramebuffer = 0;
	}
    ///////////
    if (displayFramebuffer3)
	{
		glDeleteFramebuffers(1, &displayFramebuffer3);
		displayFramebuffer3 = 0;
	}
	
	if (displayRenderbuffer3)
	{
		glDeleteRenderbuffers(1, &displayRenderbuffer3);
		displayRenderbuffer3 = 0;
	}
    
    if (displayTexture3)
    {
        glDeleteTextures(1, &displayTexture3);
        displayTexture3 = -1;
    }
    if ([GPUImageContext supportsFastTextureUpload])
    {
        [self cleanFBO];
    }
}

- (void)setDisplayFramebuffer:(int)nIndex
{
    if (!displayFramebuffer)
    {
        [self createDisplayFramebuffer:videoWidth Height:videoHeight];
    }
    
    if(nIndex == 0)
    {
        glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
        glViewport(0, 0, (GLint)_sizeInPixels.width, (GLint)_sizeInPixels.height);
        curTexture = displayTexture3;
    }
    else if(nIndex == 1)
    {
        glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer3);
        glViewport(0, 0, (GLint)displayTextureSize.width, (GLint)displayTextureSize.height);
    }
    
    [self clearScreen];
}

static const GLfloat noRotationTextureCoordinates[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,
};

- (void)presentFramebuffer
{
    [GPUImageContext setActiveShaderProgram:videoDisplayProgram];
    [self setDisplayFramebuffer:0];
    
    float vtTri[8];
    vtTri[0] = -1;
    vtTri[1] = -1;
    vtTri[2] = 1;
    vtTri[3] = -1;
    vtTri[4] = -1;
    vtTri[5] = 1;
    vtTri[6] = 1;
    vtTri[7] = 1;
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, curTexture);
    glUniform1i([videoDisplayProgram uniformIndex:@"inputImageTexture"], 0);
    
    glVertexAttribPointer([videoDisplayProgram attributeIndex:@"position"], 2, GL_FLOAT, 0, 0, vtTri);
    glVertexAttribPointer([videoDisplayProgram attributeIndex:@"inputTextureCoordinate"], 2, GL_FLOAT, 0, 0, [GLView textureCoordinatesForRotation:kGPUImageNoRotation]);
    glEnableVertexAttribArray([videoDisplayProgram attributeIndex:@"position"]);
    glEnableVertexAttribArray([videoDisplayProgram attributeIndex:@"inputTextureCoordinate"]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glActiveTexture(GL_TEXTURE0);
    glDisable(GL_TEXTURE_2D);
    
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    if([GPUImageContext sharedImageProcessingContext])
        [[GPUImageContext sharedImageProcessingContext] presentBufferForDisplay];
}

- (void)renderWithBGRForExport
{
    [GPUImageContext setActiveShaderProgram:colorSwizzlingProgram];
    if([GPUImageContext supportsFastTextureUpload])
    {
        if (!movieFramebuffer)
        {
            [self createDataFBO];
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
        glViewport(0, 0, (GLint)displayTextureSize.width, (GLint)displayTextureSize.height);
        [self clearScreen];
        
        float vtTri[] = { -1, 1,
            1, 1,
            -1, -1,
            1, -1 };
        
        glActiveTexture(GL_TEXTURE4);
        glEnable(GL_TEXTURE_2D);
        glBindTexture(GL_TEXTURE_2D, curTexture);
        glUniform1i([videoDisplayProgram uniformIndex:@"inputImageTexture"], 4);
        
        glVertexAttribPointer([videoDisplayProgram attributeIndex:@"position"], 2, GL_FLOAT, 0, 0, vtTri);
        glVertexAttribPointer([videoDisplayProgram attributeIndex:@"inputTextureCoordinate"], 2, GL_FLOAT, 0, 0, [GLView textureCoordinatesForRotation:kGPUImageNoRotation]);
        glEnableVertexAttribArray([videoDisplayProgram attributeIndex:@"position"]);
        glEnableVertexAttribArray([videoDisplayProgram attributeIndex:@"inputTextureCoordinate"]);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glActiveTexture(GL_TEXTURE4);
        glDisable(GL_TEXTURE_2D);
        glFinish();
    }
}

- (CVPixelBufferRef) getPixelBuffer
{
    return renderPixelBuffer;
}

- (void)SetFBOSizeForExport:(int)nWidth Height:(int)nHeight
{
    if (displayTextureSize.width != nWidth || displayTextureSize.height != nHeight) {
        [self destroyDisplayFramebuffer];
        [self createDisplayFramebuffer:nWidth Height:nHeight];
        if([GPUImageContext supportsFastTextureUpload])
            [self cleanFBO];
    }
    isExport = YES;
}

#pragma mark -
#pragma mark Handling fill mode

- (void)clearScreen
{
    glClearColor(0.f, 0.f, 0.f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

+ (const GLfloat *)textureCoordinatesForRotation:(GPUImageRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
    };
    
    switch(rotationMode)
    {
        case kGPUImageNoRotation: return noRotationTextureCoordinates;
        case kGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

#pragma mark -
#pragma mark GPUInput protocol

- (void)setExportEnable:(bool)enable
{
    isExport = enable;
}

- (void)DrawImageWithDistortion:(TextureInfo*)texInfo Mode:(int)mode Distortion:(CGFloat)distortion Zoom:(CGFloat)zoomScale;
{
    if(mode < DISTORTION_MAX)
    {
        [self setDisplayFramebuffer:1];
        if (texInfo.texture) {
            if(texInfo.texture)
            {
                [self applyDistortion:mode Distortion:distortion Zoom:zoomScale Texture:texInfo];
            }
        }
    }
    else
        curTexture = texInfo.texture;
    
    if (isExport) {
        [self renderWithBGRForExport];
    }
    else
        [self presentFramebuffer];
}

- (void) cleanFBO
{
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glDeleteFramebuffers(1, &movieFramebuffer);
    movieFramebuffer = 0;
    if(renderPixelBuffer)
    {
        CVPixelBufferRelease(renderPixelBuffer);
        renderPixelBuffer = nil;
    }
    
    if(renderTexture)
    {
        CFRelease(renderTexture);
        renderTexture = nil;
    }
}

- (void)createDataFBO
{
    glActiveTexture(GL_TEXTURE1);
    glGenFramebuffers(1, &movieFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, movieFramebuffer);
    // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, // our empty IOSurface properties dictionary
                               NULL,
                               NULL,
                               0,
                               &kCFTypeDictionaryKeyCallBacks,
                               &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault,
                                      1,
                                      &kCFTypeDictionaryKeyCallBacks,
                                      &kCFTypeDictionaryValueCallBacks);
    
    /* Point!. This value 'kCVPixelBufferIOSurfacePropertiesKey' in attr is very important. Must be setted for FBO. */
    CFDictionarySetValue(attrs,
                         kCVPixelBufferIOSurfacePropertiesKey,
                         empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, displayTextureSize.width, displayTextureSize.height,
                        kCVPixelFormatType_32BGRA,
                        attrs,
                        &renderPixelBuffer);
    
    CVBufferSetAttachment(renderPixelBuffer, kCVImageBufferColorPrimariesKey, kCVImageBufferColorPrimaries_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(renderPixelBuffer, kCVImageBufferYCbCrMatrixKey, kCVImageBufferYCbCrMatrix_ITU_R_601_4, kCVAttachmentMode_ShouldPropagate);
    CVBufferSetAttachment(renderPixelBuffer, kCVImageBufferTransferFunctionKey, kCVImageBufferTransferFunction_ITU_R_709_2, kCVAttachmentMode_ShouldPropagate);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault,
                                                  [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache],
                                                  renderPixelBuffer,
                                                  NULL, // texture attributes
                                                  GL_TEXTURE_2D,
                                                  GL_RGBA, // opengl format
                                                  (GLint)displayTextureSize.width,
                                                  (GLint)displayTextureSize.height,
                                                  GL_BGRA, // native iOS format
                                                  GL_UNSIGNED_BYTE,
                                                  0,
                                                  &renderTexture);
    
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
}

-(void) applyDistortion:(int)modeIndex Distortion:(CGFloat)distortion Zoom:(CGFloat)zoomScale Texture:(TextureInfo*)texInfo
{
    float pTextureCoord1[8], pTextureCoord2[8];
    memcpy(pTextureCoord1, [GLView textureCoordinatesForRotation:kGPUImageNoRotation], 8 * sizeof(float));
    memcpy(pTextureCoord2, [GLView textureCoordinatesForRotation:kGPUImageNoRotation], 8 * sizeof(float));

    GLProgram *useProgram = nil;
    [GPUImageContext setActiveShaderProgram:fishEyeProgram];
    useProgram = fishEyeProgram;
    
    float texs[] = { 0, 0, 0, 1, 1, 0, 1, 1};
    float vTri[] = { -1, -1, -1, 1, 1, -1, 1, 1};
    if (zoomScale < 1.0f)
    {
        vTri[0] = -zoomScale;
        vTri[1] = -zoomScale;
        vTri[2] = -zoomScale;
        vTri[3] = zoomScale;
        vTri[4] = zoomScale;
        vTri[5] = -zoomScale;
        vTri[6] = zoomScale;
        vTri[7] = zoomScale;
    }
    else
    {
        texs[0] = 0.5 * (zoomScale / 2 - 0.5);
        texs[1] = 0.5 * (zoomScale / 2 - 0.5);
        texs[2] = 0.5 * (zoomScale / 2 - 0.5);
        texs[3] = 0.5 * (2.5 - zoomScale / 2);
        texs[4] = 0.5 * (2.5 - zoomScale / 2);
        texs[5] = 0.5 * (zoomScale / 2 - 0.5);
        texs[6] = 0.5 * (2.5 - zoomScale / 2);
        texs[7] = 0.5 * (2.5 - zoomScale / 2);
    }

    glVertexAttribPointer([useProgram attributeIndex:@"position"], 2, GL_FLOAT, 0, 0, vTri);
    glEnableVertexAttribArray([useProgram attributeIndex:@"position"]);
    
    glVertexAttribPointer([useProgram attributeIndex:@"inputTextureCoordinate1"], 2, GL_FLOAT, 0, 0, texs);
    glEnableVertexAttribArray([useProgram attributeIndex:@"inputTextureCoordinate1"]);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri ( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, texInfo.texture);
    glUniform1i([useProgram uniformIndex:@"effect_tex"], 4);
    
    distortion_param_t param = get_distortion_profile(modeIndex);
    coefficient_param_t coeff = get_coefficient_profile(modeIndex);
    
    if(distortion > 1.0f)
    {
        float delta = distortion - 1.0;
        param.distortionParam1 += coeff.c1 * delta;
        param.distortionParam2 += coeff.c2 * delta;
        param.residualMeanError += coeff.c3 * delta;
        param.residualStandardDeviation += coeff.c4 * delta;
        param.m1 += coeff.delta1 * delta;
        param.m2 += coeff.delta2 * delta;
        param.m3 += coeff.delta3 * delta;
        param.m4 += coeff.delta4 * delta;
    }
    
    glUniform1f([useProgram uniformIndex:@"fx"], param.focalLengthX);
    glUniform1f([useProgram uniformIndex:@"fy"], param.focalLengthY);
    glUniform1f([useProgram uniformIndex:@"cx"], param.centerX);
    glUniform1f([useProgram uniformIndex:@"cy"], param.centerY);
    glUniform1f([useProgram uniformIndex:@"k1"], param.distortionParam1);
    glUniform1f([useProgram uniformIndex:@"k2"], param.distortionParam2);
    glUniform1f([useProgram uniformIndex:@"p1"], param.residualMeanError);
    glUniform1f([useProgram uniformIndex:@"p2"], param.residualStandardDeviation);
    glUniform1f([useProgram uniformIndex:@"distort"], distortion);
    glUniform1f([useProgram uniformIndex:@"m1"], param.m1);
    glUniform1f([useProgram uniformIndex:@"m2"], param.m2);
    glUniform1f([useProgram uniformIndex:@"m3"], param.m3);
    glUniform1f([useProgram uniformIndex:@"m4"], param.m4);

    glUniform1f([useProgram uniformIndex:@"zoom"], zoomScale);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end
