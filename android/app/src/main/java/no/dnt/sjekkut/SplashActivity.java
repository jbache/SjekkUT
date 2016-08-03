package no.dnt.sjekkut;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.LayerDrawable;
import android.os.Bundle;
import android.os.Handler;

import com.squareup.picasso.Picasso;
import com.squareup.picasso.Target;


public class SplashActivity extends Activity implements Target {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);
        Picasso.with(this).load(R.drawable.splash_image_1080x1920).centerCrop().resize(Utils.getDisplayWidth(this), Utils.getDisplayHeight(this)).centerCrop().into(this);

        final Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                startActivity(new Intent(SplashActivity.this, LoginActivity.class));
                overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out);
                finish();
            }
        }, 1000);
    }

    @Override
    public void onBitmapLoaded(Bitmap bitmap, Picasso.LoadedFrom from) {
        Drawable background = getWindow().getDecorView().getBackground();
        if (background instanceof LayerDrawable) {
            BitmapDrawable bitmapDrawable = new BitmapDrawable(getResources(), bitmap);
            ((LayerDrawable) background).setDrawableByLayerId(R.id.splashBackground, bitmapDrawable);
            background.invalidateSelf();
        }
    }

    @Override
    public void onBitmapFailed(Drawable errorDrawable) {

    }

    @Override
    public void onPrepareLoad(Drawable placeHolderDrawable) {

    }
}