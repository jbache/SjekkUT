package no.dnt.sjekkut.network;

import android.location.Location;

import java.util.List;

import no.dnt.sjekkut.R;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 10.08.2016.
 */
public class Place {
    public String _id;
    public String navn;
    public String kommune;
    public String fylke;
    public String beskrivelse;
    public List<Photo> bilder;
    public GeoJSON geojson;

    public Float getDistanceTo(Location currentLocation) {
        if (geojson != null) {
            Location projectLocation = geojson.getLocation();
            if (currentLocation != null && projectLocation != null) {
                return currentLocation.distanceTo(projectLocation);
            }
        }
        return null;
    }

    public boolean hasLocation() {
        return geojson != null && geojson.getLocation() != null;
    }

    public String getImageUrl(int preferredWidth) {
        if (bilder != null && bilder.size() >= 1) {
            return bilder.get(0).getImageUrl(preferredWidth);
        }
        return null;
    }

    public Place(String _id) {
        this._id = _id;
    }

    public int getImageFallback() {
        return R.drawable.project_image_fallback;
    }
}
