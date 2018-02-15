package com.moorin.distortapp;

import java.io.File;

import android.content.ContentValues;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.os.Environment;
import android.provider.MediaStore;

import com.moorin.distortapp.service.BitmapWrapper;

public class Distort {

	public static int manualFlag;
	public static Context ctx;
	
	static {
		System.loadLibrary("distort");
	}

	public static void setContext(Context _ctx){
		ctx = _ctx;
	}
	
	private static final int IMG_WMAX = 1920;
	private static final String DIR_PATH = "Distortion";
	 
	public static native void nativeSetParam(double distort, double zoom, int mode);
	public static native int  nativeSetBitmap(Bitmap bmpSrc, int width, int height, int save);

	public static native void nativeRenderInit();
	public static native void nativeRenderResize(int width, int height);
	public static native void nativeRenderFrame(int manualFlag);
	public static native void nativeSetSaveFlag(int save);
	public static native void nativeRenderEnd();

	private static OnBitmapSavedListener onBitmapSavedListener = null;

	public static void setOnBitmapSavedListener(OnBitmapSavedListener listener) {
		onBitmapSavedListener = listener;
	}

	public static void nativeOnFromBuffer(int[] buffer, int width, int height) {

		Bitmap org = BitmapWrapper.createBitmap(buffer, width, height, Bitmap.Config.ARGB_8888);
		//Bitmap org = BitmapWrapper.createBitmap(buffer, width, height, Bitmap.Config.RGB_565);
		Matrix mirror = new Matrix();
		mirror.setScale(1.0f, -1.0f);
		Bitmap capture = BitmapWrapper.createBitmap(org, 0, 0, width, height, mirror, false);
		BitmapWrapper.recycleBitmap(org);

		String dirPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM) + 
						File.separator + DIR_PATH;
		
		File dir = new File(dirPath);
		if (! dir.exists()){
			dir.mkdir();
		}
		
		String path = dir + File.separator + "image_" + System.currentTimeMillis() + ".jpg";
		
		BitmapWrapper.saveBitmapToSdcard(capture, path);
		BitmapWrapper.recycleBitmap(capture);

		addImageGallery(DIR_PATH, path);
		
		if (onBitmapSavedListener != null) {
			onBitmapSavedListener.onSaved();
		}
	}

	private static void addImageGallery( String dirName, String filePath ) {
		
		
	    ContentValues values = new ContentValues();
	    values.put(MediaStore.Images.Media.DATA, filePath);
	    values.put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg"); // setar isso
	    values.put(MediaStore.Images.Media.BUCKET_DISPLAY_NAME, "image/jpeg"); // setar isso
	    
	    ctx.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
	}
	
	public static interface OnBitmapSavedListener {
		public void onSaved();
	}
	
	
	public static Bitmap scaleBitmap(Bitmap bmp){
		
		int w = bmp.getWidth();
		int h = bmp.getHeight();
		int div = w % 2;
		
		if (w <= IMG_WMAX && h <= IMG_WMAX && div== 0 )
			return null;

		float rate = (float)w/(float)h;
		int w2, h2;
		
		if (w > IMG_WMAX){
			w2 = IMG_WMAX;
			h2 = (int)(w2 / rate);
		}else if (h > IMG_WMAX){
			h2 = IMG_WMAX;
			w2 = (int)(h2 * rate);	
		}else{
			w2 = (w >> 1) << 1;
			h2 = h;
		}
		
		Bitmap bmp2 = BitmapWrapper.createScaledBitmap(bmp, w2, h2, false);
		
		return bmp2;
	}
	
	public static void setManualFlag(int flag)
	{
		manualFlag = flag;
	}
	
	public static int getManualFlag()
	{
		return manualFlag;
	}
}
