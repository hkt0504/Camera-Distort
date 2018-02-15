#include "common.h"

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

distortion_param_t get_distortion_profile(int mode)
{
    return g_distortion_profiles[mode];
}

coefficient_param_t get_coefficient_profile(int mode)
{
    return g_coefficient_profiles[mode];
}

// RGB -> YUV
#define GET_B(CLR)	((CLR & 0x1F) << 3)
#define GET_G(CLR)	(((CLR >> 5) & 0x3F) << 2)
#define GET_R(CLR)	(((CLR >> 11) & 0x1F) << 3)

#define SAFE_FREE(v)	if(v) { free(v);v=NULL;}


typedef struct _FrameBuff
{
	int width;		// real video width
	int height;		// real video height
	int buffSize;	// video frame buffer size
	char* buff;		// video frame buffer

	int	saveFlag;
}FrameBuff;


FrameBuff* 	mBuff = NULL;

int 		glScreenW;
int 		glScreenH;
int			bpp = 0;

double 		zoomScale = 0.0f;
double 		distort = 0.0f;
int			mode = -1;


//----------------------------------------------------------------------//
// convert RGB565 to RGBA8888
int rgb565_to_rgb8888(char* src, char* dest, int width, int height)
{
	int idx;
	int idy;
	short* source = (short*)src + (width * height - 1);
	char* destination = dest + (width * height * 4 - 1);

	for (idy = 0; idy < height; idy++) {
		for (idx = 0; idx < width; idx++) {
			short clr = *source--;
			*destination-- = 255;
			*destination-- = GET_R(clr);
			*destination-- = GET_G(clr);
			*destination-- = GET_B(clr);
		}
	}

	return 1;
}

// convert BGRA8888 to RGBA8888
int bgr8888_to_rgb8888(char* src, char* dest, int width, int height)
{
	int idx;
	int idy;
	char r, g, b, a;
	for (idy = 0; idy < height; idy++) {
		for (idx = 0; idx < width; idx++) {
			r = *src++;
			g = *src++;
			b = *src++;
			a = *src++;
			*dest++ = b;
			*dest++ = g;
			*dest++ = r;
			*dest++ = a;
		}
	}

	return 1;
}

//----------------------------------------------------------------------//
jobject BitmapLock( JNIEnv* env, jobject thiz, jobject pBitmap, void** pBitmapRefPixelBuffer )
{
	jobject pBitmapRef = (*env)->NewGlobalRef(env, pBitmap); //lock the bitmap preventing the garbage collector from destructing it

	if (pBitmapRef == NULL)
	{
		*pBitmapRefPixelBuffer = NULL;
		return NULL;
	}

	int result = AndroidBitmap_lockPixels(env, pBitmapRef, pBitmapRefPixelBuffer);
	if (result != 0)
	{
		*pBitmapRefPixelBuffer = NULL;
		return NULL;
	}

	return pBitmapRef;
}

void BitmapUnlock( JNIEnv* env, jobject thiz, jobject pBitmapRef, void* pBitmapRefPixelBuffer )
{
	if (pBitmapRef)
	{
		if (pBitmapRefPixelBuffer)
		{
			AndroidBitmap_unlockPixels(env, pBitmapRef);
			pBitmapRefPixelBuffer = NULL;
		}
		(*env)->DeleteGlobalRef(env, pBitmapRef);
		pBitmapRef = NULL;
	}
}

//----------------------------------------------------------------------//
void SaveBufferToPicture(JNIEnv *env, char *buffer, jint width, jint height)
{
	NdkDbg("SaveBufferToPicture s, mBuff->saveFlag=%d", mBuff->saveFlag);

	jclass jniclass = (*env)->FindClass(env, "com/moorin/distortapp/Distort");

	if (jniclass == NULL) {
		NdkErr("QditorMainActivity not found");
		return;
	}

	jmethodID methodID = (*env)->GetStaticMethodID(env, jniclass, "nativeOnFromBuffer", "([III)V");

	if (methodID == NULL)
	{
		NdkErr("QditorMainActivity not found");
	}
	else
	{
		jsize size = (jsize) width * (jsize) height;
		jintArray array = (*env)->NewIntArray(env, size);
		jint *pixels = (jint*) buffer;
		(*env)->SetIntArrayRegion(env, array, 0, size, pixels);
		(*env)->CallStaticVoidMethod(env, jniclass, methodID, array, width, height);
	}
}

//----------------------------------------------------------------------//
// Render

void OnRenderFrame(JNIEnv* env, int manualFlag, char* pGLBuff)
{
	float vtTri[] = { -1, -1, -1, 1, 1, -1, 1, 1 };

	if (mBuff && mBuff->buff)
	{
		NdkDbg("OnRenderFrame s, mBuff->saveFlag=%d, %d*%d, manualFlag = %d", mBuff->saveFlag, mBuff->width, mBuff->height, manualFlag);

		OnGLESRender(mBuff->saveFlag,
				mBuff->buff, mBuff->width, mBuff->height);

		// save bitmap to sdcard.
		if (mBuff->saveFlag)
		{
			char* buff = (char*) malloc(mBuff->width * mBuff->height * 4);

			NdkDbg("OnRenderFrame malloc");
			GetGLColorBuffer(buff, mBuff->width, mBuff->height);

			NdkDbg("OnRenderFrame readpixel");
			// convert buffer
			if (bpp == 2)
			{
				rgb565_to_rgb8888(buff, buff, mBuff->width, mBuff->height);
			}
			else
			{
				bgr8888_to_rgb8888(buff, buff, mBuff->width, mBuff->height);
			}

			NdkDbg("OnRenderFrame convert");
			// save buffer
			SaveBufferToPicture(env, buff, mBuff->width, mBuff->height);

			NdkDbg("OnRenderFrame save");
			// release buffer
			SAFE_FREE(buff);

			mBuff->saveFlag = 0;

			NdkDbg("OnRenderFrame free");
			if (manualFlag)
				DrawSavedTexture();
		}
	}

}

//----------------------------------------------------------------------//
// set camera size

JNIEXPORT jint JNICALL Java_com_moorin_distortapp_Distort_nativeSetBitmap(JNIEnv* env, jobject thiz,
			jobject srcBmp, int width, int height, int save)
{
	NdkDbg("nativeDistort s, w=%d, h=%d", width, height);

	if ( srcBmp )
	{
		void* srcBmpBuff;

		jobject srcRef = BitmapLock(env, thiz, srcBmp, &srcBmpBuff);

		if (srcRef == NULL)
			return -1;

		int size = width * height * 2;

		NdkDbg("nativeDistort 1, size=%d", size);

		if (mBuff == NULL){
			mBuff = (FrameBuff*)malloc(sizeof(FrameBuff));
			memset(mBuff, 0, sizeof(FrameBuff));
		}

		if (mBuff->buffSize < size){

			SAFE_FREE(mBuff->buff);

			mBuff->buff = (char*)malloc(size);
			mBuff->buffSize = size;
		}

		memcpy(mBuff->buff, srcBmpBuff, size);
		mBuff->width = width;
		mBuff->height = height;
		mBuff->saveFlag = save;

		BitmapUnlock(env, thiz, srcRef, srcBmpBuff);
	}

	return 1;
}

JNIEXPORT void JNICALL Java_com_moorin_distortapp_Distort_nativeSetSaveFlag(JNIEnv* env, jobject thiz, int save)
{
	NdkDbg("nativeSetSaveFlag s, flag = %d", save);

	mBuff->saveFlag = save;
}

JNIEXPORT void JNICALL Java_com_moorin_distortapp_Distort_nativeSetParam(JNIEnv* env, jobject thiz,
				jdouble _distort, jdouble _zoom, int _mode)
{
	mode 	= _mode;
	zoomScale 	= _zoom;
	distort = _distort;
}

//----------------------------------------------------------------------//
// GLRenderer

JNIEXPORT void JNICALL Java_com_moorin_distortapp_Distort_nativeRenderInit(JNIEnv* env, jobject thiz)
{
	NdkDbg("nativeRenderInit s");

	if (mBuff == NULL){
		mBuff = (FrameBuff*)malloc(sizeof(FrameBuff));
		memset(mBuff, 0, sizeof(FrameBuff));
	}

	InitShader();
}

JNIEXPORT void JNICALL Java_com_moorin_distortapp_Distort_nativeRenderEnd(JNIEnv* env, jobject thiz)
{
	if (mBuff){
		SAFE_FREE(mBuff->buff);
		SAFE_FREE(mBuff);
	}

	ExitShader();
}


JNIEXPORT void JNICALL Java_com_moorin_distortapp_Distort_nativeRenderFrame(JNIEnv* env, jobject thiz, jint manualFlag)
{
	OnRenderFrame(env, manualFlag, NULL);
}

JNIEXPORT void JNICALL Java_com_moorin_distortapp_Distort_nativeRenderResize(JNIEnv* env, jobject thiz,
				jint width, jint height)
{
	NdkDbg("nativeRenderResize w=%d, h=%d", width, height);

	glScreenW = width;
	glScreenH = height;

	if (bpp < 1)
		bpp = GetGLBpp();

	glViewport(0, 0, width, height);
}

