package no.dnt.sjekkut.network;

import android.location.Location;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 12.08.2016.
 */
public class CheckinLocation {
    private float lat;
    private float lon;

    public CheckinLocation(Location location) {
        lat = (float) location.getLatitude();
        lon = (float) location.getLongitude();
    }
}
