package no.dnt.opptur;

import android.location.Location;

import java.io.Serializable;

/**
 * Copyright Den Norske Turistforening 2015
 *
 * Created by espen on 06.02.2015.
 */
public class Mountain implements Serializable {

    private static final int MAP_MAX_SIZE = 640;
    private static final float MAX_DISTANCE_FOR_USER_MARKER_METERS = 3000.0f;

    public static class LocationContainer implements Serializable {
        public double Lat;
        public double Lng;
    }

    public String name;
    public double height;
    public String county;
    public LocationContainer location;
    public String iconUrl;
    public String infoUrl;
    public String description;
    public long id;
    public int checkinCount;

    public Location getLocation() {
        Location l = new Location(name);
        l.setLatitude(location.Lat);
        l.setLongitude(location.Lng);
        return l;
    }

    public String getImageUrl() {
        if (iconUrl != null && !iconUrl.trim().isEmpty())
            return iconUrl;
        else
            return null;
    }

    public String getInfoUrl() {
        if (infoUrl != null && !infoUrl.trim().isEmpty())
            return infoUrl;
        else
            return null;
    }

    public String getMapUrl(int width, int height, Location userLocation, int zoomLevel) {
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

        String latLong = getLocation().getLatitude() + "," + getLocation().getLongitude();
        String widthHeight = width + "x" + height;
        int scale = 2;
        String staticMapUrl = "https://maps.googleapis.com/maps/api/staticmap?center=" + latLong + "&zoom=" + zoomLevel + "&size=" + widthHeight + "&scale=" + scale + "&maptype=terrain&key=AIzaSyDSn0vYqHUuazbG5PPIYm-HYu-Wi2qbcCM&markers=" + latLong;
        if (userLocation != null && getLocation().distanceTo(userLocation) < MAX_DISTANCE_FOR_USER_MARKER_METERS) {
            staticMapUrl += "&markers=color:green%7C" + userLocation.getLatitude() + "," + userLocation.getLongitude();
        }
        return staticMapUrl;
    }

    @Override
    public String toString() {
        return name + " - " + county;
    }
}
