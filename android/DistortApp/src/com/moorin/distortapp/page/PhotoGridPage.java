package com.moorin.distortapp.page;

import java.util.ArrayList;

import android.content.Context;
import android.content.CursorLoader;
import android.content.Intent;
import android.content.Loader;
import android.content.Loader.OnLoadCompleteListener;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.provider.MediaStore;
import android.util.SparseArray;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.BaseAdapter;
import android.widget.GridView;
import android.widget.ImageView;
import android.widget.Toast;

import com.moorin.distortapp.R;
import com.moorin.distortapp.WaitDialog;
import com.moorin.distortapp.service.ImageShower;

public class PhotoGridPage extends BasePage {

	private static final int REQ_ALBUM = 100;

	private GridView mGridView;
	private boolean mMultiple;
	private SparseArray<String> mCheckedArray = new SparseArray<String>();;
	private ImageAdapter mImageAdapter;

	@Override
	protected void onCreateView() {
		super.onCreateView();
		setContentView(R.layout.page_photogrid);

		if (mMultiple) {
			setTitle("Select Photos", "Album", "Next");
		} else {
			setTitle("Select Photo", "Album", "Cancel");
		}

		mGridView = (GridView) findViewById(R.id.gridView);
		mGridView.setOnItemClickListener(new OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
				if (mMultiple) {
					multiSelect(position);
				} else {
					selectPosition(position);
				}
			}
		});

		mImageAdapter = new ImageAdapter(getContext());
		mGridView.setAdapter(mImageAdapter);
		loadPhotos(null);
	}

	public void setMultiple(boolean multiple) {
		this.mMultiple = multiple;
	}

	private void loadPhotos(String album) {
		if (mMultiple) {
			mCheckedArray.clear();
		}

		final WaitDialog waitDialog = new WaitDialog(getMain());
		waitDialog.show();

		String[] proj = { MediaStore.Images.Media._ID,
				MediaStore.Images.Media.DATA,
				MediaStore.Images.Thumbnails._ID };

		String selection = null;
		String[] selectionArgs = null;
		if (album != null) {
			selection = MediaStore.Images.Media.BUCKET_DISPLAY_NAME + "=?";
			selectionArgs = new String[] {album};
		}

		CursorLoader cursorLoader = new CursorLoader(getContext(), MediaStore.Images.Media.EXTERNAL_CONTENT_URI, proj,
				selection, selectionArgs, MediaStore.Images.Media.DATE_ADDED + " DESC");
		cursorLoader.registerListener(0, new OnLoadCompleteListener<Cursor>() {
			@Override
			public void onLoadComplete(Loader<Cursor> loader, Cursor data) {
				mImageAdapter.clearPhotos();
				int dataIndex = data.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
				int thumbnailIndex = data.getColumnIndexOrThrow(MediaStore.Images.Thumbnails._ID);

				while (data.moveToNext()) {
					PhotoItem photoItem = new PhotoItem();
					photoItem.path = data.getString(dataIndex);
					photoItem.thumbnail = data.getLong(thumbnailIndex);
					mImageAdapter.addPhoto(photoItem);
				}

				mImageAdapter.notifyDataSetChanged();
				waitDialog.cancel();
			}
		});
		cursorLoader.startLoading();
	}

	private void selectPosition(int position) {
		PhotoItem item = mImageAdapter.getItem(position);
		if (item != null) {
			Intent intent = new Intent();
			intent.putExtra("imagePath", item.path);
			setResult(RESULT_OK, intent);
			finish();
		}
	}

	private void multiSelect(int position) {
		if (mCheckedArray.get(position) != null) {
			mCheckedArray.remove(position);
		} else {
			PhotoItem item = mImageAdapter.getItem(position);
			mCheckedArray.append(position, item.path);
		}
		mImageAdapter.notifyDataSetChanged();
	}

	@Override
	protected void onClickTitleLeft() {
		AlbumPage page = new AlbumPage();
		showPageForResult(REQ_ALBUM, page);
	}

	@Override
	protected void onClickTitleRight() {
		if (mMultiple) {
			int size = mCheckedArray.size();
			if (size == 0) {
				Toast.makeText(getContext(), "Please select photo", Toast.LENGTH_SHORT).show();
			} else {
				SelCameraPage page = new SelCameraPage();
				ArrayList<String> paths = new ArrayList<String>();
				for (int i = 0; i < size; i++) {
					String path = mCheckedArray.valueAt(i);
					paths.add(path);
				}
				page.setFileNames(paths);
				showPage(page);
			}
		} else {
			setResult(RESULT_CANCEL);
			finish();
		}
	}

	@Override
	protected void onPageResult(int request, int result, Intent data) {
		if (request == REQ_ALBUM && result == RESULT_OK) {
			String album = data.getStringExtra("album");
			loadPhotos(album);
		}
	}

	private static class PhotoItem {
		public String path;
		public long thumbnail;
	}

	public class ImageAdapter extends BaseAdapter {

		private ImageShower mImageShower;
		private ArrayList<PhotoItem> mPhotos = new ArrayList<PhotoItem>();

		public ImageAdapter(Context context) {
			mImageShower = new ImageShower(context.getContentResolver());
		}

		public void clearPhotos() {
			mImageShower.clearCache();
			mPhotos.clear();
		}

		public void addPhoto(PhotoItem item) {
			mPhotos.add(item);
		}

		@Override
		public int getCount() {
			return mPhotos.size();
		}

		@Override
		public PhotoItem getItem(int position) {
			return mPhotos.get(position);
		}

		@Override
		public long getItemId(int position) {
			return position;
		}

		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			View view;
			if (convertView == null) {
				view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_photo, parent, false);
			} else {
				view = convertView;
			}

			final ImageView imageView = (ImageView) view.findViewById(R.id.img_thumb);
			imageView.setImageResource(android.R.drawable.gallery_thumb);
			if (imageView != null) {
				imageView.setTag(position);
				if (mMultiple) {
					imageView.setAlpha((mCheckedArray.get(position) == null) ? 1.f : 0.5f);
				}

				PhotoItem item = getItem(position);
				mImageShower.getImage(position, item.thumbnail, new ImageShower.ImageShowListener() {
					@Override
					public void onImagePrepared(int position, Bitmap bitmap) {
						if ((Integer) imageView.getTag() == position) {
							imageView.setImageBitmap(bitmap);
						}
					}
				});
			}

			return view;
		}
	}
}