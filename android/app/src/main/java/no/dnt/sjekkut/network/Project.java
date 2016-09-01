package no.dnt.sjekkut.network;

import android.content.Context;
import android.location.Location;

import java.util.List;

import no.dnt.sjekkut.R;
import no.dnt.sjekkut.Utils;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 09.08.2016.
 */
public class Project {
    private static final String HOMEPAGE = "Hjemmeside";
    public String _id;
    public String navn;
    public List<Place> steder;
    public List<Photo> bilder;
    public List<Group> grupper;
    List<Link> lenker;

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

    public Float getDistanceTo(Location currentLocation) {
        Float shortestDistance = null;
        if (steder != null && !steder.isEmpty()) {
            for (Place place : steder) {
                Float distanceToPlace = place.getDistanceTo(currentLocation);
                if (distanceToPlace != null) {
                    if (shortestDistance == null || distanceToPlace < shortestDistance) {
                        shortestDistance = distanceToPlace;
                    }
                }

            }
        }
        return shortestDistance;
    }

    public String getDistanceToString(Context context, Location currentLocation) {
        if (context != null) {
            Float distance = getDistanceTo(currentLocation);
            if (distance != null) {
                return Utils.formatDistance(context, distance);
            }
        }
        return "n/a";
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

    public String getBackgroundUrl(int preferredWidth) {
        if (bilder != null && bilder.size() >= 2) {
            return bilder.get(1).getImageUrl(preferredWidth);
        }
        return null;
    }

    public int getBackgroundFallback() {
        return R.drawable.project_background_fallback;
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
}
