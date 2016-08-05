package no.dnt.sjekkut;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */

public class PreferenceUtils {

    private final static String ACCESS_TOKEN = "access_token";
    private final static String REFRESH_TOKEN = "refresh_token";

    public static boolean hasAccessToken(Context context) {
        return getPreferences(context).contains(ACCESS_TOKEN);
    }

    public static boolean hasRefreshToken(Context context) {
        return getPreferences(context).contains(REFRESH_TOKEN);
    }

    public static void setAccessAndRefreshToken(Context context, String access_token, String refresh_token) {
        SharedPreferences.Editor editor = getPreferences(context).edit();
        editor.putString(ACCESS_TOKEN, access_token);
        editor.putString(REFRESH_TOKEN, refresh_token);
        editor.apply();
    }

    public static String getBearerAuthorization(Context context) {
        return "Bearer " + getPreferences(context).getString(ACCESS_TOKEN, "access_token_missing");
    }

    public static String getRefreshToken(Context context) {
        return getPreferences(context).getString(REFRESH_TOKEN, "refresh_token_missing");
    }

    private static SharedPreferences getPreferences(Context context) {
        return PreferenceManager.getDefaultSharedPreferences(context.getApplicationContext());
    }
}
