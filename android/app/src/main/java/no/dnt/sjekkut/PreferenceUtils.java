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
    private final static String USER_ID = "user_id";
    private final static String USER_FULLNAME = "user_fullname";

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
        return "Bearer " + getAccessToken(context);
    }

    public static String getRefreshToken(Context context) {
        return getPreferences(context).getString(REFRESH_TOKEN, "refresh_token_missing");
    }

    private static SharedPreferences getPreferences(Context context) {
        return PreferenceManager.getDefaultSharedPreferences(context.getApplicationContext());
    }

    static void clearLoginInformation(Context context) {
        SharedPreferences.Editor editor = getPreferences(context).edit();
        editor.remove(ACCESS_TOKEN);
        editor.remove(REFRESH_TOKEN);
        editor.remove(USER_ID);
        editor.remove(USER_FULLNAME);
        editor.apply();
    }

    public static void setUserIdandFullname(Context context, String userId, String fullname) {
        SharedPreferences.Editor editor = getPreferences(context).edit();
        editor.putString(USER_ID, userId);
        editor.putString(USER_FULLNAME, fullname);
        editor.apply();
    }

    public static String getUserId(Context context) {
        return getPreferences(context).getString(USER_ID, "user_id_missing");
    }

    public static String getUserFullname(Context context) {
        return getPreferences(context).getString(USER_FULLNAME, "user_fullname_missing");
    }

    public static String getAccessToken(Context context) {
        return getPreferences(context).getString(ACCESS_TOKEN, "access_token_missing");
    }

    public static boolean hasUserId(Context context) {
        return getPreferences(context).contains(USER_ID);
    }
}
