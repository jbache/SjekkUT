package no.dnt.sjekkut.network;

import android.content.Context;
import android.location.Location;

import java.util.List;

import no.dnt.sjekkut.Utils;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 09.08.2016.
 */
public class Project {
    public String _id;
    public String navn;
    public String beskrivelse;
    public List<Place> steder;
    public List<Photo> bilder;
    public List<Group> grupper;
    public GeoJSON geojson;


    public int getPlaceCount() {
        return steder != null ? steder.size() : 0;
    }

    public String getFirstGroupName() {
        if (grupper != null && !grupper.isEmpty() && grupper.get(0).navn != null) {
            return grupper.get(0).navn;
        } else {
            return "n/a";
        }
    }

    public String getDistanceTo(Context context, Location currentLocation) {
        if (context != null && geojson != null) {
            Location projectLocation = geojson.getLocation();
            if (currentLocation != null && projectLocation != null) {
                return Utils.formatDistance(context, currentLocation.distanceTo(projectLocation));
            }
        }
        return "n/a";
    }
}
