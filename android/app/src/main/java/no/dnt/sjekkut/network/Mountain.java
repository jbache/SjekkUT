package no.dnt.sjekkut.network;

import android.location.Location;

import java.io.Serializable;

/**
 * Copyright Den Norske Turistforening 2015
 *
 * Created by espen on 06.02.2015.
 */
public class Mountain implements Serializable {



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

    @Override
    public String toString() {
        return name + " - " + county;
    }
}
