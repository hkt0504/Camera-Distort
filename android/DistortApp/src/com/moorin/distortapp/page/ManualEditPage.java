package com.moorin.distortapp.page;

import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.view.SurfaceHolder;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
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

public class ManualEditPage extends BasePage {

	private static final int REQ_PHOTOGRID = 100;

	WheelView 		wheelView;
	ZoomImageView 	imageView;
	SeekBar 		zoomSeekBar;
	SeekBar 		distortSeekBar;

	private final String wheelData[] = new String[] { "HERO3 Black",
			"HERO3 Silver", 
			"HERO3 White", 
	"HERO3+ Black"};

	private String imgPath = null;

	@Override
	protected void onCreateView() {
		super.onCreateView();
		setContentView(R.layout.page_manualedit);
		setTitle(null, "New Image", "Save");

		ArrayWheelAdapter<String> adapter = new ArrayWheelAdapter<String>(getContext(), wheelData);

		wheelView = (WheelView) findViewById(R.id.slot_1);
		wheelView.setViewAdapter(adapter);
		wheelView.setCurrentItem((int) (Math.random() * 10));
		wheelView.setVisibleItems(3);

		wheelView.addChangingListener(changedListener);
		wheelView.addScrollingListener(scrolledListener);
		wheelView.setCyclic(false);
		wheelView.setEnabled(true);


		zoomSeekBar = (SeekBar) findViewById(R.id.zoomSeekBar);
		zoomSeekBar.setOnSeekBarChangeListener(mSeekBarListener);
		zoomSeekBar.setProgress(500);

		distortSeekBar = (SeekBar) findViewById(R.id.distortSeekBar);
		distortSeekBar.setOnSeekBarChangeListener(mSeekBarListener);
		distortSeekBar.setProgress(500);

		imageView = (ZoomImageView) findViewById(R.id.CameraView);
		imageView.setSurfaceCB(new ZoomImageView.SurfaceViewListener() {

			@Override
			public void surfaceDestroyed(SurfaceHolder holder) {
				// TODO Auto-generated method stub
				onSurfaceDestroyed();
			}

			@Override
			public void surfaceCreated(SurfaceHolder holder) {
				// TODO Auto-generated method stub
				onSurfaceCreated();
			}

			@Override
			public void surfaceChanged(SurfaceHolder holder, int w, int h) {
				// TODO Auto-generated method stub
				onSurfaceChanged();
			}
		});

		Distort.setManualFlag(1);
		setImagePath(imgPath);
		setParam();
	}

	private void onSurfaceCreated(){
	}

	private void onSurfaceDestroyed(){
	}

	private void onSurfaceChanged(){
		imageView.requestRender();
	}

	public void setImagePath(String path) {

		BitmapFactory.Options options = new BitmapFactory.Options();
		options.inPreferredConfig = Bitmap.Config.RGB_565;
		
		Bitmap bitmap = null;
		if (path == null) {
			
			bitmap = BitmapFactory.decodeResource(getResources(), R.drawable.default_background, options);
		} else {
			bitmap = BitmapFactory.decodeFile(path, options);
		}

		// resize bitmap
		Bitmap bitmap2 = Distort.scaleBitmap(bitmap);

		if (bitmap2 == null){
			Distort.nativeSetBitmap(bitmap, bitmap.getWidth(), bitmap.getHeight(), 0);
		}else{
			Distort.nativeSetBitmap(bitmap2, bitmap2.getWidth(), bitmap2.getHeight(), 0);
			bitmap2.recycle();
			bitmap2 = null;
		}

		bitmap.recycle();
		bitmap = null;
		
		imageView.requestRender();
	}

	private final OnSeekBarChangeListener mSeekBarListener = new OnSeekBarChangeListener() {

		@Override
		public void onStopTrackingTouch(SeekBar seekBar) {
		}

		@Override
		public void onStartTrackingTouch(SeekBar seekBar) {
		}

		@Override
		public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
			if (!fromUser)
				return;

			switch (seekBar.getId()) {
			case R.id.zoomSeekBar:
			case R.id.distortSeekBar:
				setParam();
				break;
			}
		}
	}; 


	@Override
	protected void onClickTitleLeft() {
		PhotoGridPage page = new PhotoGridPage();
		showPageForResult(REQ_PHOTOGRID, page);
	}

	@Override
	protected void onClickTitleRight() {
		final WaitDialog waitDialog = new WaitDialog(getMain());
		waitDialog.show();
		ImageSaver imageSaver = new ImageSaver(null);
		imageSaver.setOnProcessListener(new ImageSaver.OnProcessListener() {
			@Override
			public void onSaveProcess(String filePath) {
				Distort.nativeSetSaveFlag(1);
				imageView.requestRender();
			}
		});
		imageSaver.setOnCompleteListener(new ImageSaver.OnCompleteListener() {
			@Override
			public void onCompleted() {
				waitDialog.cancel();
				Toast.makeText(getContext(), "Image Saved", Toast.LENGTH_SHORT).show();
			}
		});
		imageSaver.saveBitmap(null);
	}

	@Override
	protected void onPageResult(int request, int result, Intent data) {

		if (request == REQ_PHOTOGRID && result == RESULT_OK) {
			imgPath = data.getStringExtra("imagePath");
			setImagePath(imgPath);
		}
	}

	// zoom : 0 ~ 1000
	private void setParam(){

		int zoom = zoomSeekBar.getProgress();
		float fZoom = 0.0f; 
		if (zoom < 500){
			fZoom = 0.5f + (zoom / 1000.f);
		}else{
			fZoom = (zoom / 500.f);
		}

		int distort = distortSeekBar.getProgress();
		float fDistort = (float)distort / 500.f;

		int mode = wheelView.getCurrentItem();

		imageView.setParam(fDistort, fZoom, mode);
	}


	// Wheel scrolled listener
	OnWheelScrollListener scrolledListener = new OnWheelScrollListener() {

		public void onScrollingStarted(WheelView wheel) {

		}

		public void onScrollingFinished(WheelView wheel) {

			setParam();
		}
	};

	// Wheel changed listener
	private OnWheelChangedListener changedListener = new OnWheelChangedListener() {
		public void onChanged(WheelView wheel, int oldValue, int newValue) {

		}
	};


}
