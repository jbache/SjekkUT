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

    public static boolean hasAccessToken(Context context) {
        return getPreferences(context).contains(ACCESS_TOKEN);
    }

    public static void setAccessToken(Context context, String access_token) {
        SharedPreferences.Editor editor = getPreferences(context).edit();
        editor.putString(ACCESS_TOKEN, access_token);
        editor.apply();
    }

    public static String getBearerAuthorization(Context context) {
        return "Bearer " + getPreferences(context).getString(ACCESS_TOKEN, "tokenmissing");
    }

    private static SharedPreferences getPreferences(Context context) {
        return PreferenceManager.getDefaultSharedPreferences(context.getApplicationContext());
    }
}
