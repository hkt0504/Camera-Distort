package com.moorin.distortapp;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

import android.opengl.GLSurfaceView;

public class GLRenderer implements GLSurfaceView.Renderer {

	public GLRenderer() {
	}

	public void onDrawFrame(GL10 gl) {
		// TODO Auto-generated method stub
		Distort.nativeRenderFrame(Distort.getManualFlag());
	}

	public void onSurfaceChanged(GL10 gl, int width, int height) {
		// TODO Auto-generated method stub
		Distort.nativeRenderResize(width, height);
	}

	public void onSurfaceCreated(GL10 gl, EGLConfig config) {
		// TODO Auto-generated method stub
		
		Distort.nativeRenderInit();
	}
	
}
