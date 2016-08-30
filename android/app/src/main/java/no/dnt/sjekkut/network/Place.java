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
    private static final String HOMEPAGE = "Hjemmeside";
    public String _id;
    public String navn;
    public String kommune;
    public String fylke;
    public String beskrivelse;
    public List<Photo> bilder;
    public GeoJSON geojson;
    List<Link> lenker;

    public Place(String _id) {
        this._id = _id;
    }

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
        return getLocation() != null;
    }

    public Location getLocation() {
        return geojson != null ? geojson.getLocation() : null;
    }

    public String getImageUrl(int preferredWidth) {
        if (bilder != null && bilder.size() >= 1) {
            return bilder.get(0).getImageUrl(preferredWidth);
        }
        return null;
    }

    public int getImageFallback() {
        return R.drawable.project_image_fallback;
    }

    public String getHomePageUrl() {
        if (lenker != null) {
            for (Link link : lenker) {
                if (HOMEPAGE.equals(link.type)) {
                    return link.url;
                }
            }
        }
        return null;
    }

    private static class Link {
        String type;
        String url;
    }
}
