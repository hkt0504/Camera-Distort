package com.moorin.distortapp;

import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.lang.Thread.UncaughtExceptionHandler;

import android.content.Context;
import android.os.Environment;
import android.os.Looper;

public class AppLogHandler implements UncaughtExceptionHandler {

	public static final String AGR_LOG_DIRECOTORY = "Distortion";
	
	private Thread.UncaughtExceptionHandler mDefaultHandler;
	private static AppLogHandler instance;

	private AppLogHandler() {
	}

	public static AppLogHandler getInstance() {
		if (instance == null) {
			instance = new AppLogHandler();
		}
		return instance;
	}

	public void init(Context context) {
		mDefaultHandler = Thread.getDefaultUncaughtExceptionHandler();
		Thread.setDefaultUncaughtExceptionHandler(this);
	}

	@Override
	public void uncaughtException(Thread thread, Throwable ex) {
		
		if (!handleException(ex) && mDefaultHandler != null) {
			mDefaultHandler.uncaughtException(thread, ex);
		} else {
			try {
				Thread.sleep(3000);
			} catch (Exception e) {
				e.printStackTrace();
			}
			android.os.Process.killProcess(android.os.Process.myPid());
			System.exit(10);
		}
	}

	private boolean handleException(final Throwable ex) {
		if (ex == null) {
			return false;
		}

		new Thread() {
			@Override
			public void run() {
				
				Looper.prepare();
				
				createLogDirectory();
				String fileName =  "crash-" + System.currentTimeMillis() + ".log";
				
				File file = new File(
						Environment.getExternalStorageDirectory()+ File.separator +AGR_LOG_DIRECOTORY, fileName);
				try {
					FileWriter fw = new FileWriter(file, true);
					ex.printStackTrace(new PrintWriter(fw, true));
					fw.close();
					
					} catch (Exception e) {
				}
				Looper.loop();
			}
		}.start();
		
		return false;
	}
	
	private void createLogDirectory() {
		File file = new File(Environment.getExternalStorageDirectory(), AGR_LOG_DIRECOTORY);
		try {
			if (!file.exists() || !file.isDirectory()) {
				file.mkdir();
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}


