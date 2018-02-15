package com.moorin.distortapp.page;

import java.util.ArrayList;

import android.content.CursorLoader;
import android.content.Intent;
import android.content.Loader;
import android.content.Loader.OnLoadCompleteListener;
import android.database.Cursor;
import android.provider.MediaStore;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.BaseAdapter;
import android.widget.ListView;
import android.widget.TextView;

import com.moorin.distortapp.R;

public class AlbumPage extends BasePage {

	ListView listView;
	private AlbumAdapter albumAdapter;

	@Override
	protected void onCreateView() {
		super.onCreateView();
		setContentView(R.layout.page_album);

		setTitle("Select Album", "Back", null);

		listView = (ListView) findViewById(R.id.listView);
		listView.setOnItemClickListener(new OnItemClickListener() {
			@Override
			public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
				selectPosition(position);
			}
		});

		loadAlbums();
	}

	private void loadAlbums() {
		String[] proj = { "DISTINCT " + MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME };
		CursorLoader cursorLoader = new CursorLoader(getContext(), MediaStore.Images.Media.EXTERNAL_CONTENT_URI, proj,
				null, null, MediaStore.Images.Media.BUCKET_DISPLAY_NAME + " ASC");
		cursorLoader.registerListener(0, new OnLoadCompleteListener<Cursor>() {
			@Override
			public void onLoadComplete(Loader<Cursor> loader, Cursor data) {
				int index = data.getColumnIndex(MediaStore.Images.ImageColumns.BUCKET_DISPLAY_NAME);
				albumAdapter = new AlbumAdapter();
				while (data.moveToNext()) {
					albumAdapter.add(data.getString(index));
				}
				listView.setAdapter(albumAdapter);
			}
		});
		cursorLoader.startLoading();
	}

	private void selectPosition(int position) {
		Intent intent = new Intent();
		intent.putExtra("album", albumAdapter.getItem(position));
		setResult(RESULT_OK, intent);
		finish();
	}

	@Override
	protected void onClickTitleLeft() {
		finish();
	}

	@Override
	protected void onClickTitleRight() {
	}


	public class AlbumAdapter extends BaseAdapter {

		ArrayList<String> albums = new ArrayList<String>();

		public AlbumAdapter() {
		}

		public void add(String album) {
			albums.add(album);
		}

		@Override
		public int getCount() {
			return albums.size();
		}

		@Override
		public String getItem(int position) {
			return albums.get(position);
		}

		@Override
		public long getItemId(int position) {
			return position;
		}

		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			View view;
			if (convertView == null) {
				view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_album, parent, false);
			} else {
				view = convertView;
			}

			TextView textView = (TextView) view.findViewById(R.id.txtName);
			textView.setText(getItem(position));
			return view;
		}
	}
}