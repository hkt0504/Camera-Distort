package com.moorin.distortapp.page;

import com.moorin.distortapp.R;

public class SavePage extends BasePage {

	boolean intentFlag;

	@Override
	protected void onCreateView() {
		super.onCreateView();
		setContentView(R.layout.page_save);

		setTitle("Saving", "Back", "New");
	}

	public void setSaveFrom(boolean from) {
		intentFlag = from;
	}

	@Override
	protected void onClickTitleLeft() {
		finish();
	}

	@Override
	protected void onClickTitleRight() {
		backToFirstPage();
	}

}
