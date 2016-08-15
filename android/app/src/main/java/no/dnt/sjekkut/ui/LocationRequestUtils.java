package no.dnt.sjekkut.ui;

import com.google.android.gms.location.LocationRequest;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 15.08.2016.
 */

public class LocationRequestUtils {

    public static LocationRequest repeatingRequest() {
        LocationRequest request = LocationRequest.create();
        request.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
        request.setInterval(10000);
        request.setSmallestDisplacement(20);
        return request;
    }

    public static LocationRequest singleShotRequest() {
        LocationRequest request = LocationRequest.create();
        request.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
        request.setFastestInterval(500);
        request.setInterval(1000);
        request.setSmallestDisplacement(0);
        request.setNumUpdates(1);
        return request;
    }
}
