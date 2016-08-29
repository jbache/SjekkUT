package no.dnt.sjekkut.network;

import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.TimeZone;

/**
 * * Copyright Den Norske Turistforening 2016
 * <p/>
 * Created by Espen on 29.08.2016.
 */

public enum DateSingleton {
    INSTANCE;

    private final ThreadLocal<SimpleDateFormat> mSimpleDateFormatThreadLocal = new ThreadLocal<SimpleDateFormat>() {
        @Override
        protected SimpleDateFormat initialValue() {
            //String EXAMPLE = "2016-08-28 T 10:28:43.121Z"
            String PATTERN = "yyyy-MM-dd'T'HH:mm:ss.SSS";
            SimpleDateFormat dateFormat = new SimpleDateFormat(PATTERN, Locale.US);
            String TIMEZONE = "GMT";
            dateFormat.setTimeZone(TimeZone.getTimeZone(TIMEZONE));
            return dateFormat;
        }
    };

    public static SimpleDateFormat getDateFormat() {
        return INSTANCE.mSimpleDateFormatThreadLocal.get();
    }
}