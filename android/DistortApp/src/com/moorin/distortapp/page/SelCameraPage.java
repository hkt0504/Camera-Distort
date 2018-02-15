package com.moorin.distortapp.page;

import java.util.List;

import android.widget.Toast;

import com.moorin.distortapp.Distort;
import com.moorin.distortapp.R;
import com.moorin.distortapp.WaitDialog;
import com.moorin.distortapp.ZoomImageView;
import com.moorin.distortapp.service.ImageSaver;
import com.moorin.distortapp.wheelview.ArrayWheelAdapter;
import com.moorin.distortapp.wheelview.OnWheelChangedListener;
import com.moorin.distortapp.wheelview.OnWheelScrollListener;
import com.moorin.distortapp.wheelview.WheelView;

public class SelCameraPage extends BasePage {

	private static final String wheelData[] = new String[] { 
						"HERO3 Black",
						"HERO3 Silver", 
						"HERO3 White", 
						"HERO3+ Black"};
	
	private List<String> fileNames = null;
	private ZoomImageView surfaceView;

	@Override
	protected void onCreateView() {
		super.onCreateView();
		setContentView(R.layout.page_selcamera);

		setTitle("Select Camera", "Back", "Save");
		
		ArrayWheelAdapter<String> adapter = new ArrayWheelAdapter<String>(getContext(), wheelData);

		WheelView wheel = (WheelView) findViewById(R.id.slot_2);
		wheel.setViewAdapter(adapter);
		wheel.setCurrentItem((int) (Math.random() * 10));
		wheel.setVisibleItems(7);

		wheel.addChangingListener(changedListener);
		wheel.addScrollingListener(scrolledListener);
		wheel.setCyclic(false);
		wheel.setEnabled(true);
		
		surfaceView = (ZoomImageView) findViewById(R.id.surfaceView);
		Distort.setManualFlag(0);
	}

	public void setFileNames(List<String> fileNames) {
		this.fileNames = fileNames;
	}

	@Override
	protected void onClickTitleLeft() {
		finish();
	}

	@Override
	protected void onClickTitleRight() {
		final WaitDialog waitDialog = new WaitDialog(getMain());
		waitDialog.show();
		ImageSaver saver = new ImageSaver(surfaceView);
		saver.setOnCompleteListener(new ImageSaver.OnCompleteListener() {
			@Override
			public void onCompleted() {
				waitDialog.cancel();
				Toast.makeText(getContext(), "Image Saved", Toast.LENGTH_SHORT).show();
			}
		});
		saver.saveBitmaps(fileNames);

		SavePage page = new SavePage();
		page.setSaveFrom(false);
		showPage(page);
	}

	// Wheel scrolled listener
	OnWheelScrollListener scrolledListener = new OnWheelScrollListener() {
		public void onScrollingStarted(WheelView wheel) {

		}

		public void onScrollingFinished(WheelView wheel) {

			Toast.makeText(getContext(), wheelData[wheel.getCurrentItem()], Toast.LENGTH_LONG).show();
		}
	};

	// Wheel changed listener
	private OnWheelChangedListener changedListener = new OnWheelChangedListener() {
		public void onChanged(WheelView wheel, int oldValue, int newValue) {

		}
	};


}
