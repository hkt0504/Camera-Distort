package com.moorin.distortapp.service;

import java.util.List;
import java.util.Queue;
import java.util.concurrent.LinkedBlockingQueue;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.opengl.GLSurfaceView;
import android.os.AsyncTask;
import android.util.Log;

import com.moorin.distortapp.Distort;

public class ImageSaver {

	private static final String TAG = "ImageSaver";

	private final Queue<ImageItem> mQueue;
	private boolean mIsCanceled;
	private boolean mIsRunning;
	private GLSurfaceView mSurfaceView;
	private OnProcessListener mOnProcessListener = null;
	private OnCompleteListener mOnCompleteListener = null;

	private class ImageItem {
		public String path = null;

		public ImageItem(String path) {
			this.path = path;
		}
	}

	public ImageSaver(GLSurfaceView surfaceView) {
		mSurfaceView = surfaceView;
		mQueue = new LinkedBlockingQueue<ImageItem>();
		mIsCanceled = false;
		mIsRunning = false;
	}

	public void setOnProcessListener(OnProcessListener listener) {
		mOnProcessListener = listener;
	}

	public void setOnCompleteListener(OnCompleteListener listener) {
		mOnCompleteListener = listener;
	}

	public void saveBitmaps(List<String> paths) {
		mIsCanceled = false;

		for (String path : paths) {
			if (path.trim().length() == 0) {
				continue;
			}

			synchronized (mQueue) {
				mQueue.add(new ImageItem(path));
			}
		}

		// if running then insert queue after return
		if (mIsRunning)
			return;
		mIsRunning = true;

		ImageSaver.SaveTask task = new ImageSaver.SaveTask();
		task.execute();
	}

	public void saveBitmap(String path) {
		if (path == null && mOnProcessListener == null) {
			return;
		}
		mIsCanceled = false;

		synchronized (mQueue) {
			mQueue.add(new ImageItem(path));
		}

		// if running then insert queue after return
		if (mIsRunning)
			return;
		mIsRunning = true;

		ImageSaver.SaveTask task = new ImageSaver.SaveTask();
		task.execute();
	}

	public void clearQueue() {
		mIsCanceled = true;
		mIsRunning = false;

		synchronized (mQueue) {
			mQueue.clear();
		}
	}


	private class SaveTask extends AsyncTask<Object, ImageItem, Object> {
		private Boolean mSaved = false;

		public SaveTask() {
		}

		@Override
		protected Object doInBackground(Object... params) {
			while (true) {
				// check if ending by outside
				if (mIsRunning == false) {
					Log.i(TAG, "run() thread terminate");
					return null;
				}

				if (mIsCanceled) {
					return null;
				}

				// self finishing if Queue in finished 
				ImageItem item = null;
				synchronized (mQueue) {
					item = mQueue.poll();
				}

				if (item == null) {
					mIsRunning = false;
					Log.i(TAG, "run() thread terminate, queue is empty");
					return null;
				}

				setSaved(false);

				Distort.setOnBitmapSavedListener(new Distort.OnBitmapSavedListener() {
					@Override
					public void onSaved() {
						setSaved(true);
					}
				});

				if (mOnProcessListener != null) {
					mOnProcessListener.onSaveProcess(item.path);
				} else {
					BitmapFactory.Options options = new BitmapFactory.Options();
					options.inPreferredConfig = Bitmap.Config.RGB_565;
					
					Bitmap bitmap = BitmapFactory.decodeFile(item.path, options);
					if (bitmap != null) {
						Bitmap bitmap2 = Distort.scaleBitmap(bitmap);

						if (bitmap2 == null) {
							Distort.nativeSetBitmap(bitmap, bitmap.getWidth(), bitmap.getHeight(), 1);
						} else {
							Distort.nativeSetBitmap(bitmap2, bitmap2.getWidth(), bitmap2.getHeight(), 1);
							bitmap2.recycle();
							bitmap2 = null;
						}

						bitmap.recycle();
						bitmap = null;
					}

					mSurfaceView.requestRender();
				}

				while (!mSaved) {
					try {
						Thread.sleep(10);
					} catch (InterruptedException e) {
					}
				}
			}
		}

		private void setSaved(boolean saved) {
			synchronized (mSaved) {
				mSaved = saved;
			}
		}

		@Override
		protected void onPostExecute(Object result) {
			super.onPostExecute(result);
			mOnCompleteListener.onCompleted();
		}

	}


	public static interface OnProcessListener {
		public void onSaveProcess(String filePath);
	}

	public static interface OnCompleteListener {
		public void onCompleted();
	}
}
