#ifndef __COMMON_H__
#define __COMMON_H__


#include <jni.h>
#include <android/log.h>
#include <pthread.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>



#define SAFE_FREE(v)			if(v) { free(v);v=NULL;}

// ----------------------- LOG PRINT -----------------------//

enum android_LogPriority2 {
    ANDROID_LOG_UNKNOWN2 = 0,
    ANDROID_LOG_DEFAULT2,    /* only for SetMinPriority() */
    ANDROID_LOG_VERBOSE2,
    ANDROID_LOG_DEBUG2,
    ANDROID_LOG_INFO2,
    ANDROID_LOG_WARN2,
    ANDROID_LOG_ERROR2,
    ANDROID_LOG_FATAL2,
    ANDROID_LOG_SILENT2,     /* only for SetMinPriority(); must be last */
};

#define NdkLog(...)				//__android_log_print(ANDROID_LOG_INFO2,  "NdkLog", __VA_ARGS__)
#define NdkErr(...)				//__android_log_print(ANDROID_LOG_ERROR2, "NdkLog", __VA_ARGS__)
#define NdkDbg(...)				//__android_log_print(ANDROID_LOG_DEBUG2, "NdkLog", __VA_ARGS__)

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

#endif //__COMMON_H__
