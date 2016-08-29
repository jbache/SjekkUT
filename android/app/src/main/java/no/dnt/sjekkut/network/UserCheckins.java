package no.dnt.sjekkut.network;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
            // TODO: find latest using timestamp
            return checkins.get(0);
        }
    }

    private List<PlaceCheckin> getCheckins(String placeId) {
        initLookupMap();
        return mCheckinMap.containsKey(placeId) ? mCheckinMap.get(placeId) : new ArrayList<PlaceCheckin>();
    }

    private static class UserCheckinsData {
        String _id;
        String epost;
        String navn;
        String __v;
        List<PlaceCheckin> innsjekkinger;
    }
}
