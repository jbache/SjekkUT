package no.dnt.sjekkut.network;

import java.util.List;

/**
 * Created by Espen on 28.08.2016.
 */
public class UserCheckins {
    private UserCheckinsData data;

    public int getNumberOfVisits(String placeId) {
        int visits = 0;
        if (getCheckins() != null && placeId != null) {
            for (PlaceCheckin checkin : getCheckins()) {
                if (placeId.equals(checkin.ntb_steder_id)) {
                    ++visits;
                }
            }
        }
        return visits;
    }

    public List<PlaceCheckin> getCheckins() {
        if (data != null && data.innsjekkinger != null) {
            return data.innsjekkinger;
        } else {
            return null;
        }
    }

    private static class UserCheckinsData {
        String _id;
        String epost;
        String navn;
        String __v;
        List<PlaceCheckin> innsjekkinger;
    }
}
