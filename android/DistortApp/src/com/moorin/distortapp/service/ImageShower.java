package com.moorin.distortapp.service;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.Queue;
import java.util.concurrent.LinkedBlockingQueue;

import android.content.ContentResolver;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.BitmapFactory.Options;
import android.graphics.Rect;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.util.Log;

public class ImageShower {

	private static final String TAG = "ImageShower";

	private static final int CACHE_BUFFER = 100;
	private static final int QUEUE_BUFFER = 20;

	private final ArrayList<ImageItem> mCachedList;
	private final Queue<ImageItem> mLoadingQueue;
	private boolean mIsCanceled;
	private boolean mIsRunning;

	private ContentResolver mContentResolver;

	public ImageShower(ContentResolver cr) {
		mCachedList = new ArrayList<ImageItem>();
		mLoadingQueue = new LinkedBlockingQueue<ImageItem>();
		mIsCanceled = false;
		mIsRunning = false;
		mContentResolver = cr;
	}

	public void getImage(int position, long thumbnail, ImageShowListener listener) {
		mIsCanceled = false;

		// if image exists in cache data
		ImageItem item = null;
		int size = mCachedList.size();
		for (int i = 0; i < size; i++) {
			item = mCachedList.get(i);
			if (item.position == position) {
				if (item.bitmap != null) {
					listener.onImagePrepared(position, item.bitmap);
					return;
				} else {
					mCachedList.remove(i);
					break;
				}
			}
		}

		synchronized (mLoadingQueue) {
			while (mLoadingQueue.size() >= QUEUE_BUFFER) {
				mLoadingQueue.poll();
			}

			item = new ImageItem(position, thumbnail, listener);
			mLoadingQueue.add(item);
		}

		// if running then insert queue after return
		if (mIsRunning)
			return;
		mIsRunning = true;

		ImageShower.ShowTask task = new ImageShower.ShowTask();
		task.execute();
	}

	public void clearQueue() {
		Log.i(TAG, "clearQueue()");

		mIsCanceled = true;
		mIsRunning = false;

		mLoadingQueue.clear();
	}

	public void clearCache() {
		mCachedList.clear();
	}

	public static Bitmap decodeStream(InputStream is, Rect outPadding, Options opts) {
		Log.i(TAG, "decodeStream()");
		if (opts == null) {
			opts = new BitmapFactory.Options();
			opts.inSampleSize = 1;
			opts.inPurgeable = true;
			opts.inDither = true;
		}
		Bitmap bitmap = null;
		try {
			bitmap = BitmapFactory.decodeStream(is, outPadding, opts);
		} catch (OutOfMemoryError e) {
			Log.e(TAG, "decodeStream()", e);
		}

		Log.i(TAG, "decodeStream() bitmap " + bitmap);
		return bitmap;
	}

	private class ShowTask extends AsyncTask<Object, ImageItem, Object> {
		public ShowTask() {
		}

		@Override
		protected Object doInBackground(Object... params) {
			while (true) {
				// check if ending by outside
				if (mIsRunning == false) {
					Log.i(TAG, "run() thread terminate");
					return null;
				}

				// self finishing if Queue in finished 
				ImageItem item = null;
				synchronized (mLoadingQueue) {
					item = mLoadingQueue.poll();
				}

				if (item == null) {
					mIsRunning = false;
					Log.i(TAG, "run() thread terminate, queue is empty");
					return null;
				}

				BitmapFactory.Options options = new BitmapFactory.Options();
				options.inSampleSize = 1;
				item.bitmap = MediaStore.Images.Thumbnails.getThumbnail(mContentResolver, item.thumbnail, MediaStore.Images.Thumbnails.MINI_KIND, options);
				this.publishProgress(item);
			}
		}

		@Override
		protected void onProgressUpdate(ImageItem... values) {
			Log.i(TAG, "canceled " + mIsCanceled);
			// if cancelled then do not call listener
			ImageItem item = values[0];
			if (item != null) {
				if (item.bitmap != null) {
					while (mCachedList.size() >= CACHE_BUFFER) {
						mCachedList.remove(0);
					}

					mCachedList.add(item);
				}

				if (mIsCanceled == false) {
					if (item.listener != null) {
						item.listener.onImagePrepared(item.position, item.bitmap);
						item.listener = null;
					}
				}
			}
		}
	}

	private static class ImageItem {
		int position;
		long thumbnail;
		Bitmap bitmap;
		ImageShowListener listener;

		public ImageItem(int position, long thumbnail, ImageShowListener listener) {
			this.position = position;
			this.thumbnail = thumbnail;
			this.listener = listener;
		}
	}

	public static interface ImageShowListener {
		public void onImagePrepared(int position, Bitmap bitmap);
	}
}
