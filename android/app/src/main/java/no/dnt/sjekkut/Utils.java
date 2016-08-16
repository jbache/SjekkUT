package no.dnt.sjekkut;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.graphics.Point;
import android.graphics.PorterDuff;
import android.location.Location;
import android.location.LocationManager;
import android.os.Build;
import android.provider.Settings;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.text.format.DateUtils;
import android.view.Display;
import android.view.View;
import android.view.WindowManager;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.widget.Toast;

import org.apache.http.NameValuePair;
import org.apache.http.client.utils.URLEncodedUtils;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Date;
import java.util.List;

import no.dnt.sjekkut.network.Checkin;
import no.dnt.sjekkut.network.Mountain;
import no.dnt.sjekkut.ui.LoginActivity;
import timber.log.Timber;

/**
 * Copyright Den Norske Turistforening 2015
 * <p>
 * Created by espen on 09.02.2015.
 */
public class Utils {

    private static Toast sGlobalToast = null;

    public static String getDeviceID(Context context) {
        if (context == null)
            return null;

        return Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
    }

    public static void setActionBarTitle(Activity activity, String title) {
        if (activity instanceof AppCompatActivity) {
            ActionBar actionBar = ((AppCompatActivity) activity).getSupportActionBar();
            if (actionBar != null) {
                actionBar.setTitle(title);
            }
        }
    }

    public static void toggleUpButton(Activity activity, boolean enabled) {
        if (activity instanceof AppCompatActivity) {
            ActionBar actionBar = ((AppCompatActivity) activity).getSupportActionBar();
            if (actionBar != null) {
                actionBar.setHomeButtonEnabled(enabled);
                actionBar.setDisplayHomeAsUpEnabled(enabled);
            }
        }
    }

    public static void shareCheckin(Activity activity, Checkin checkin, Mountain mMountain) {
        if (activity == null || checkin == null || mMountain == null)
            return;

        String timespan = getTimeSpanFromNow(checkin.timestamp);
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        String shareString = activity.getString(R.string.share_text, checkin.mountain, activity.getString(R.string.app_name), timespan);
        String shareUrl = mMountain.getInfoUrl();
        if (shareUrl != null) {
            shareString += " " + shareUrl;
        }
        sendIntent.putExtra(Intent.EXTRA_TEXT, shareString);
        sendIntent.setType("text/plain");
        activity.startActivity(Intent.createChooser(sendIntent, activity.getResources().getText(R.string.share_choose_title)));
    }

    public static boolean isAccurateGPSEnabled(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            return getLocationMode(context) == Settings.Secure.LOCATION_MODE_HIGH_ACCURACY;
        } else {
            return isGpsEnabled(context) && isNetworkLocationEnabled(context);
        }
    }

    private static boolean isGpsEnabled(Context context) {
        return isProviderEnabled(context, LocationManager.GPS_PROVIDER);
    }

    private static boolean isNetworkLocationEnabled(Context context) {
        return isProviderEnabled(context, LocationManager.NETWORK_PROVIDER);
    }

    private static boolean isProviderEnabled(Context context, String provider) {
        LocationManager locationManager = (LocationManager) context.getSystemService(Context.LOCATION_SERVICE);
        return locationManager != null && locationManager.isProviderEnabled(provider);
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    private static int getLocationMode(Context context) {
        return Settings.Secure.getInt(context.getContentResolver(), Settings.Secure.LOCATION_MODE, Settings.Secure.LOCATION_MODE_OFF);
    }

    public static void showToast(Context context, String text) {
        if (context == null)
            return;

        showOverride(context, text, Toast.LENGTH_LONG);
    }

    private static void showOverride(Context context, String text, int length) {
        if (sGlobalToast != null) {
            sGlobalToast.cancel();
        }
        sGlobalToast = Toast.makeText(context, text, length);
        sGlobalToast.show();
    }

    public static Checkin getLatestCheckin(List<Checkin> checkins, Mountain mountain) {
        Checkin latest = null;
        for (Checkin checkin : checkins) {
            if (mountain != null && checkin.mountainId == mountain.id) {
                if (latest == null) {
                    latest = checkin;
                } else if (checkin.timestamp.after(latest.timestamp)) {
                    latest = checkin;
                }
            }
        }
        return latest;
    }

    public static String getTimeSpanFromNow(Date then) {
        return DateUtils.getRelativeTimeSpanString(then.getTime(), new Date().getTime(), 0).toString();
    }

    public static int getDisplayWidth(Context context) {
        if (context == null) {
            return 0;
        }
        WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Display display = wm.getDefaultDisplay();
        Point size = new Point();
        display.getSize(size);
        return size.x;
    }

    public static int getDisplayHeight(Activity activity) {
        if (activity == null) {
            return 0;
        }
        Display display = activity.getWindowManager().getDefaultDisplay();
        Point size = new Point();
        display.getSize(size);
        return size.y;
    }


    public static void setColorFilter(View view, Integer filter) {
        if (filter == null) {
            view.getBackground().clearColorFilter();
        } else {
            view.getBackground().setColorFilter(filter, PorterDuff.Mode.DARKEN);
        }
    }

    public static String formatDistance(Context context, double meters) {
        if (meters < 1000) {
            return context.getString(R.string.distance_meters, meters);
        } else {
            return context.getString(R.string.distance_km, meters / 1000.0d);
        }
    }

    public static String getQuantityStringWithZero(Resources resources, int pluralResourceID, int zeroStringID, int count) {
        if (count == 0) {
            return resources.getString(zeroStringID);
        } else {
            return resources.getQuantityString(pluralResourceID, count, count);
        }
    }

    public static double getMetersPerPixelForGoogleStaticMaps(Location location, int zoomLevel) {
        if (location == null)
            return 0.0d;

        // Inspired from http://gis.stackexchange.com/a/127949 and Google
        return 156543.03392d * Math.cos(location.getLatitude() * Math.PI / 180) / Math.pow(2, zoomLevel);
    }

    public static String extractUrlArgument(String url, String name, String defaultValue) {
        if (url != null && name != null) {
            try {
                List<NameValuePair> valuePairs = URLEncodedUtils.parse(new URI(url), "UTF-8");
                for (NameValuePair pair : valuePairs) {
                    if (name.equals(pair.getName())) {
                        return pair.getValue();
                    }
                }
            } catch (URISyntaxException ignored) {
            }
        }
        return defaultValue;
    }

    // credit http://stackoverflow.com/a/31950789/1666063
    @SuppressWarnings("deprecation")
    public static void clearCookies(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            CookieManager.getInstance().removeAllCookies(null);
            CookieManager.getInstance().flush();
        } else {
            CookieSyncManager cookieSyncManager = CookieSyncManager.createInstance(context);
            cookieSyncManager.startSync();
            CookieManager cookieManager = CookieManager.getInstance();
            cookieManager.removeAllCookie();
            cookieManager.removeSessionCookie();
            cookieSyncManager.stopSync();
            cookieSyncManager.sync();
        }
    }

    public static void logout(Context context) {
        Timber.i("logout()");
        PreferenceUtils.clearLoginInformation(context);
        Intent loginActivity = new Intent(context, LoginActivity.class);
        loginActivity.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(loginActivity);
    }
}
