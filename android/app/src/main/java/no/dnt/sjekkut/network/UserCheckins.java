package no.dnt.sjekkut.network;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
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

    private Set<String> getJoinedProjects() {
        return data != null ? data.lister : null;
    }

    public boolean updateJoinedProjects(UserCheckins userCheckins) {
        if (data != null) {
            if (data.lister == null) {
                data.lister = new HashSet<>();
            }
            data.lister.clear();
            Set<String> updatedList = userCheckins.getJoinedProjects();
            if (updatedList != null) {
                data.lister.addAll(updatedList);
            }
            return true;
        }
        return false;
    }

    public int getTotalNumberOfVisits() {
        if (data != null && data.innsjekkinger != null) {
            return data.innsjekkinger.size();
        } else {
            return 0;
        }
    }

    public int getNumberOfVisitsAfter(long time) {
        int result = 0;
        if (data != null && data.innsjekkinger != null) {
            for (PlaceCheckin checkin : data.innsjekkinger) {
                if (checkin.timestamp != null && checkin.timestamp.getTime() > time) {
                    ++result;
                }
            }
        }
        return result;
    }

    public int getNumberOfProjects() {
        if (data != null && data.lister != null) {
            return data.lister.size();
        } else {
            return 0;
        }
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
