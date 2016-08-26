package no.dnt.sjekkut;

import android.app.Application;
import android.content.Context;

import com.facebook.stetho.Stetho;
import com.jakewharton.picasso.OkHttp3Downloader;
import com.squareup.picasso.Picasso;

import no.dnt.sjekkut.network.OkHttpSingleton;
import timber.log.Timber;

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
        if (BuildConfig.DEBUG) {
            Timber.plant(new Timber.DebugTree());
            Stetho.initializeWithDefaults(this);
        }
        Picasso.setSingletonInstance(new Picasso.Builder(this)
                .downloader(new OkHttp3Downloader(OkHttpSingleton.getClient()))
                .build());
    }
}
