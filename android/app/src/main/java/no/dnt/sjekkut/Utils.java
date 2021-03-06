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
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Build;
import android.provider.Settings;
import android.support.v7.app.ActionBar;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
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

import no.dnt.sjekkut.ui.LoginActivity;

/**
 * Copyright Den Norske Turistforening 2015
 * <p>
 * Created by espen on 09.02.2015.
 */
public class Utils {

    private static final int MAP_MAX_SIZE = 640;
    private static final float MAX_DISTANCE_FOR_USER_MARKER_METERS = 3000.0f;
    private static Toast sGlobalToast = null;

    public static void setupSupportToolbar(Activity activity, Toolbar toolbar, String title, boolean upButton) {
        setSupportActionToolbar(activity, toolbar);
        setActionBarTitle(activity, title);
        toggleUpButton(activity, upButton);
    }

    private static void setSupportActionToolbar(Activity activity, Toolbar toolbar) {
        if (activity instanceof AppCompatActivity) {
            ((AppCompatActivity) activity).setSupportActionBar(toolbar);
        }
    }

    private static void setActionBarTitle(Activity activity, String title) {
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

    public static String getTimeSpanFromNow(Date thenDate, String overrideFuture) {
        long then = thenDate.getTime();
        long now = new Date().getTime();
        if (then > now && overrideFuture != null) {
            return overrideFuture;
        } else {
            return DateUtils.getRelativeTimeSpanString(then, now, 0).toString();
        }
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
        PreferenceUtils.clearLoginInformation(context);
        Intent loginActivity = new Intent(context, LoginActivity.class);
        loginActivity.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(loginActivity);
    }

    public static <T extends Comparable<T>> int nullSafeCompareTo(final T one, final T two) {
        if (one == null ^ two == null) {
            return (one == null) ? 1 : -1;
        }

        if (one == null) {
            return 0;
        }

        return one.compareTo(two);
    }

    public static int nullSafeCompareTo(final String one, final String two) {
        if (one == null ^ two == null) {
            return (one == null) ? 1 : -1;
        }

        if (one == null) {
            return 0;
        }

        return one.compareToIgnoreCase(two);
    }

    public static String getMapUrl(int width, int height, Location mapLocation, Location userLocation, int zoomLevel) {
        if (width > MAP_MAX_SIZE || height > MAP_MAX_SIZE) {
            float scaleFactor;
            if (height > width) {
                scaleFactor = MAP_MAX_SIZE / (float) height;
            } else {
                scaleFactor = MAP_MAX_SIZE / (float) width;
            }
            width *= scaleFactor;
            height *= scaleFactor;
        }

        String latLong = mapLocation.getLatitude() + "," + mapLocation.getLongitude();
        String widthHeight = width + "x" + height;
        int scale = 2;
        String staticMapUrl = "https://maps.googleapis.com/maps/api/staticmap?center=" + latLong + "&zoom=" + zoomLevel + "&size=" + widthHeight + "&scale=" + scale + "&maptype=terrain&key=AIzaSyDSn0vYqHUuazbG5PPIYm-HYu-Wi2qbcCM&markers=" + latLong;
        if (userLocation != null && mapLocation.distanceTo(userLocation) < MAX_DISTANCE_FOR_USER_MARKER_METERS) {
            staticMapUrl += "&markers=color:green%7C" + userLocation.getLatitude() + "," + userLocation.getLongitude();
        }
        return staticMapUrl;
    }

    public static void sharePlaceVisit(Context context, String placeName, String shareUrl) {
        Intent shareIntent = new Intent(Intent.ACTION_SEND);
        shareIntent.setType("text/plain");
        shareIntent.putExtra(Intent.EXTRA_SUBJECT, context.getString(R.string.share_visit_text, placeName));
        shareIntent.putExtra(Intent.EXTRA_TEXT, shareUrl);
        context.startActivity(Intent.createChooser(shareIntent, "Del ditt besøk"));
    }

    public static boolean isConnected(Context context) {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo netInfo = cm.getActiveNetworkInfo();
        return netInfo != null && netInfo.isConnectedOrConnecting();
    }
}
