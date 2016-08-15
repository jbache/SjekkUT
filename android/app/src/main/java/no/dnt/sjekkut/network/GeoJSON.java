package no.dnt.sjekkut.network;

import android.location.Location;

import java.util.List;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 15.08.2016.
 */
class GeoJSON {
    private List<Float> coordinates;

    public Location getLocation() {
        if (coordinates != null && coordinates.size() >= 2) {
            Location location = new Location("GeoJSON");
            location.setLatitude(coordinates.get(1));
            location.setLongitude(coordinates.get(0));
            return location;
        } else {
            return null;
        }
    }
}
