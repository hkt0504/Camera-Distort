package com.moorin.distortapp;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.view.Window;
import android.widget.ProgressBar;

public class WaitDialog extends Dialog {

	public WaitDialog(Context context) {
		super(context);
		initUI();
	}

	private void initUI() {
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
		setCancelable(false);
		setCanceledOnTouchOutside(false);

		ProgressBar progress = new ProgressBar(this.getContext());
		setContentView(progress);
	}

	@Override
	public void show() {
		try {
			super.show();
		} catch (Exception e) {
		}
	}

	@Override
	public void dismiss() {
		try {
			super.dismiss();
		} catch (Exception e) {
		}
	}

	@Override
	public void cancel() {
		try {
			super.cancel();
		} catch (Exception e) {
		}
	}

}
