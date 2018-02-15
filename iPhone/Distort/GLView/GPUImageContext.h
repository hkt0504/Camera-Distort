#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#import "GLProgram.h"


#define GPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kGPUImageRotateLeft || (rotation) == kGPUImageRotateRight || (rotation) == kGPUImageRotateRightFlipVertical || (rotation) == kGPUImageRotateRightFlipHorizontal)

typedef enum { kGPUImageNoRotation, kGPUImageRotateLeft, kGPUImageRotateRight, kGPUImageFlipVertical, kGPUImageFlipHorizonal, kGPUImageRotateRightFlipVertical, kGPUImageRotateRightFlipHorizontal, kGPUImageRotate180 } GPUImageRotationMode;

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

extern NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString;
extern NSString *const kGPUImageVertexShaderString;
extern NSString *const kGPUImagePassthroughFragmentShaderString;

void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));

//----------- texture info of video, photo -------------------------//

@interface TextureInfo : NSObject

@property(nonatomic, assign) uint    texture; // texture index
@property(nonatomic, assign) uint    width;   // video(photo) width
@property(nonatomic, assign) uint    height;  // video(photo) height
@property(nonatomic, assign) int     rotateAngle;
@property(nonatomic, assign) bool    isOriginAspect;

- (void)unloadTexture;
@end

@interface GPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readwrite, retain, nonatomic) GLProgram *currentShaderProgram;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;

+ (void *)contextKey;
+ (GPUImageContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (void)useImageProcessingContext;
+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
- (void)removeAllPrograms;
- (void)useSharegroup:(EAGLSharegroup *)sharegroup;
+(void) loadTextureFromImage:(CGImageRef)img TextureInfo:(TextureInfo*)info;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end