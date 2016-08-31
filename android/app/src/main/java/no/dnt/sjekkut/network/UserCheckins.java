package no.dnt.sjekkut.network;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Created by Espen on 28.08.2016.
 */
public class UserCheckins {
    private UserCheckinsData data;
    private transient Map<String, List<PlaceCheckin>> mCheckinMap = null;

    public int getNumberOfVisits(String placeId) {
        return getCheckins(placeId).size();
    }

    public boolean hasVisited(String placeId) {
        initLookupMap();
        return mCheckinMap.containsKey(placeId);
    }

    public Set<String> getVisitedPlaceIds() {
        initLookupMap();
        return mCheckinMap.keySet();
    }

    private void initLookupMap() {
        if (mCheckinMap == null) {
            mCheckinMap = new HashMap<>();
            if (data != null && data.innsjekkinger != null) {
                for (PlaceCheckin checkin : data.innsjekkinger) {
                    String key = checkin.ntb_steder_id;
                    if (!mCheckinMap.containsKey(key)) {
                        mCheckinMap.put(key, new ArrayList<PlaceCheckin>());
                    }
                    mCheckinMap.get(key).add(checkin);
                }
            }
        }
    }

    public PlaceCheckin getLatestCheckin(String placeId) {
        List<PlaceCheckin> checkins = getCheckins(placeId);

        if (checkins.isEmpty()) {
            return null;
        } else {
            PlaceCheckin latestCheckin = null;
            for (PlaceCheckin currentCheckin : checkins) {
                if (latestCheckin == null) {
                    latestCheckin = currentCheckin;
                } else if (latestCheckin.timestamp.before(currentCheckin.timestamp)) {
                    latestCheckin = currentCheckin;
                }
            }
            return latestCheckin;
        }
    }

    private List<PlaceCheckin> getCheckins(String placeId) {
        initLookupMap();
        return mCheckinMap.containsKey(placeId) ? mCheckinMap.get(placeId) : new ArrayList<PlaceCheckin>();
    }

    public boolean hasJoined(String projectId) {
        return data != null && data.lister != null && data.lister.contains(projectId);
    }

    private static class UserCheckinsData {
        String _id;
        String epost;
        String navn;
        String __v;
        List<PlaceCheckin> innsjekkinger;
        Set<String> lister;
    }
}
