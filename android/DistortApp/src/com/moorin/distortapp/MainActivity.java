package com.moorin.distortapp;

import android.app.Activity;
import android.app.FragmentManager;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

import com.moorin.distortapp.page.BasePage;
import com.moorin.distortapp.page.ManualEditPage;
import com.moorin.distortapp.page.PhotoGridPage;

public class MainActivity extends Activity implements OnClickListener {

	private static final int TAB_MANUAL = 1;
	private static final int TAB_ATOMATIC = 2;

	private int currentTab = 0;

	private Button btnManual;
	private Button btnAutomatic;

	private ManualEditPage mManualEditPage;
	private PhotoGridPage mAutomaticPage;

	// for log
	private AppLogHandler m_LogHandler;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);

		m_LogHandler = AppLogHandler.getInstance();
		m_LogHandler.init(this);

		Distort.setContext(this);
		
		initButton();
		showManualEditPage();
		btnManual.setSelected(true);
	}

	@Override
	protected void onDestroy()
	{
		super.onDestroy();
		Distort.nativeRenderEnd();
	}

	private void initButton() {
		btnManual = (Button)findViewById(R.id.id_btnManualPage);
		btnManual.setOnClickListener(this);

		btnAutomatic = (Button)findViewById(R.id.id_btnAutomaticPage);
		btnAutomatic.setOnClickListener(this);
	}

	public void addPage(BasePage page) {
		getFragmentManager().beginTransaction().add(R.id.content_frame, page).addToBackStack(null).commit();
	}

	public void removePage(BasePage page) {
		getFragmentManager().popBackStack();
		getFragmentManager().beginTransaction().remove(page).commit();
	}

	public void switchPage(BasePage page) {
		getFragmentManager().beginTransaction().replace(R.id.content_frame, page).commit();
	}

	public void backToFirstPage() {
		getFragmentManager().popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE);
	}

	@Override
	public void onClick(View v) {

		switch(v.getId()) {
		case R.id.id_btnManualPage:
			showManualEditPage();
			break;

		case R.id.id_btnAutomaticPage:
			showAutomaticPage();
			break;
		}
	}

	private void showManualEditPage() {
		if (currentTab != TAB_MANUAL) {
			btnManual.setSelected(true);
			btnAutomatic.setSelected(false);

			if (mManualEditPage == null) {
				mManualEditPage = new ManualEditPage();
			}

			switchPage(mManualEditPage);
			currentTab = TAB_MANUAL;
		}
	}

	private void showAutomaticPage() {
		if (currentTab != TAB_ATOMATIC) {
			btnManual.setSelected(false);
			btnAutomatic.setSelected(true);

			if (mAutomaticPage == null) {
				mAutomaticPage = new PhotoGridPage();
				mAutomaticPage.setMultiple(true);
			}

			switchPage(mAutomaticPage);
			currentTab = TAB_ATOMATIC;
		}
	}

}
