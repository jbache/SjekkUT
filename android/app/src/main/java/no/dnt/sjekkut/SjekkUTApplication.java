package no.dnt.sjekkut;

import android.app.Application;
import android.content.Context;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 05.08.2016.
 */
public class SjekkUTApplication extends Application {

    private static SjekkUTApplication instance;

    public static Context getContext() {
        return instance.getApplicationContext();
    }

    @Override
    public void onCreate() {
        instance = this;
        super.onCreate();
    }
}
