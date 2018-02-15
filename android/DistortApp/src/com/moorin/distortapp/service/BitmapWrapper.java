package com.moorin.distortapp.service;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Bitmap.Config;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Rect;

public class BitmapWrapper {

	public static Bitmap createBitmap(Bitmap src) {
		return checkNew(Bitmap.createBitmap(src), src);
	}

	public static Bitmap createBitmap(Bitmap source, int x, int y, int width, int height) {
		return checkNew(Bitmap.createBitmap(source, x, y, width, height), source);
	}

	public static Bitmap createBitmap(Bitmap source, int x, int y, int width, int height, Matrix m, boolean filter) {
		return checkNew(Bitmap.createBitmap(source, x, y, width, height, m, filter), source);
	}

	public static Bitmap createScaledBitmap(Bitmap src, int dstWidth, int dstHeight, boolean filter) {
		return checkNew(Bitmap.createScaledBitmap(src, dstWidth, dstHeight, filter), src);
	}

	private static Bitmap checkNew(Bitmap bitmap, Bitmap src) {
		return (bitmap != src) ? bitmap : src.copy(src.getConfig(), true);
	}

	public static Bitmap createBitmap(int width, int height, Config config) {
		return Bitmap.createBitmap(width, height, config);
	}

	public static Bitmap createBitmap(int colors[], int width, int height, Config config) {
		return Bitmap.createBitmap(colors, width, height, config);
	}

	public static Bitmap decodeResource(Resources res, int id) {
		return BitmapFactory.decodeResource(res, id);
	}

	public static void recycleBitmap(Bitmap bmp) {
		if (bmp != null) {
			if (!bmp.isRecycled())
				bmp.recycle();
		}
		bmp = null;
	}

	public static Bitmap bitmapFromBuffer(byte[] pBuffer, int dwBufSize, int nSampleSize) {
		Bitmap pResult = null;

		if (pBuffer == null)
			return pResult;

		BitmapFactory.Options opt = new BitmapFactory.Options();
		opt.inSampleSize = nSampleSize;

		pResult = BitmapFactory.decodeByteArray(pBuffer, 0, dwBufSize);
		opt = null;

		return pResult;
	}

	public static Bitmap BitmapFromSize(int nWidth, int nHeight, Config config) {
		return createBitmap(nWidth, nHeight, Bitmap.Config.ARGB_8888);
	}


	public static void setBitmapData(Bitmap src, Bitmap dest) {
		Canvas canvas = new Canvas(dest);
		if ((src!=null) && (dest!=null))
			canvas.drawBitmap(src, new Rect(0, 0, src.getWidth(), src.getHeight()), new Rect(0, 0, dest.getWidth(), dest.getHeight()), null);
	}

	public static void saveBitmapToSdcard(Bitmap bitmap, String fileName) {
		try {
			File bitmapFile = new File(fileName);
			FileOutputStream bitmapWtriter = new FileOutputStream(bitmapFile);
			bitmap.compress(Bitmap.CompressFormat.JPEG, 90, bitmapWtriter);
		} catch (FileNotFoundException e) {
		}
	}

}
