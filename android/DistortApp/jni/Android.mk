LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := libdistort

LOCAL_C_INCLUDES += $(LOCAL_PATH)


LOCAL_SRC_FILES := distort.c ffopengles2.cpp  

LOCAL_LDLIBS := -lz -llog -ljnigraphics -lGLESv1_CM -lGLESv2 

LOCAL_ARM_MODE := arm

include $(BUILD_SHARED_LIBRARY)

$(call import-module,android/cpufeatures)
