package com.moorin.distortapp.page;

import android.app.Fragment;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.TextView;

import com.moorin.distortapp.MainActivity;
import com.moorin.distortapp.R;

public class BasePage extends Fragment {

	static final int RESULT_CANCEL = 0;
	static final int RESULT_OK = 1;

	LayoutInflater inflater;
	View rootView;
	ViewGroup container;

	FrameLayout contentFrame;
	private Button leftBtn;
	private Button rightBtn;
	private TextView titleView;

	// for result
	BasePage resultPage;
	int requestCode;
	int result;
	Intent resultData;

	@Override
	public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
		this.inflater = inflater;
		this.container = container;

		rootView = inflater.inflate(R.layout.base_page, container, false);
		rootView.setBackgroundColor(Color.WHITE);
		contentFrame = (FrameLayout) rootView.findViewById(R.id.content);

		initTitle();
		onCreateView();

		this.inflater = null;
		this.container = null;
		return rootView;
	}

	@Override
	public void onDestroyView() {
		super.onDestroyView();
	}

	private void initTitle() {
		leftBtn = (Button) findViewById(R.id.btnLeft);
		rightBtn = (Button) findViewById(R.id.btnRight);

		leftBtn.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				onClickTitleLeft();
			}
		});

		rightBtn.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				onClickTitleRight();
			}
		});

		titleView = (TextView) findViewById(R.id.txtTitle);
	}

	protected void setTitleContent(int title, int left, int right) {
		if (title == 0) {
			titleView.setVisibility(View.INVISIBLE);
		} else {
			titleView.setText(title);
			titleView.setVisibility(View.VISIBLE);
		}

		if (left == 0) {
			leftBtn.setVisibility(View.INVISIBLE);
		} else {
			leftBtn.setText(left);
			leftBtn.setVisibility(View.VISIBLE);
		}

		if (right == 0) {
			rightBtn.setVisibility(View.INVISIBLE);
		} else {
			rightBtn.setText(right);
			rightBtn.setVisibility(View.VISIBLE);
		}
	}

	protected void setTitle(String title, String left, String right) {
		if (title == null) {
			titleView.setVisibility(View.INVISIBLE);
		} else {
			titleView.setText(title);
			titleView.setVisibility(View.VISIBLE);
		}

		if (left == null) {
			leftBtn.setVisibility(View.INVISIBLE);
		} else {
			leftBtn.setText(left);
			leftBtn.setVisibility(View.VISIBLE);
		}

		if (right == null) {
			rightBtn.setVisibility(View.INVISIBLE);
		} else {
			rightBtn.setText(right);
			rightBtn.setVisibility(View.VISIBLE);
		}
	}

	protected void setContentView(int layoutid) {
		inflater.inflate(layoutid, contentFrame, true);
	}

	protected void setContentView(View view) {
		contentFrame.addView(view);
	}

	protected View findViewById(int viewid) {
		return rootView.findViewById(viewid);
	}

	protected MainActivity getMain() {
		return (MainActivity) getActivity();
	}

	protected Context getContext() {
		return getActivity().getApplicationContext();
	}

	protected void showPage(BasePage page) {
		page.resultPage = null;
		getMain().addPage(page);
	}

	protected void showPageForResult(int request, BasePage page) {
		page.requestCode = request;
		page.resultPage = this;
		getMain().addPage(page);
	}

	protected void backToFirstPage() {
		getMain().backToFirstPage();
	}

	protected void finish() {
		getMain().removePage(this);
		if (resultPage != null) {
			resultPage.onPageResult(requestCode, result, resultData);
			resultPage = null;
		}
	}

	protected void setResult(int result) {
		this.result = result;
	}

	protected void setResult(int result, Intent data) {
		this.result = result;
		this.resultData = data;
	}

	protected void onCreateView() {
		// Do Nothing: subclass override
	}

	protected void onClickTitleLeft() {
		// Do Nothing: subclass override
	}

	protected void onClickTitleRight() {
		// Do Nothing: subclass override
	}

	protected void onPageResult(int request, int result, Intent data) {
		// Do Nothing: subclass override
	}
}
