package no.dnt.sjekkut.network;

import java.util.Date;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public class PlaceCheckin {
    public String dnt_user_id;
    public String ntb_steder_id;
    public Date timestamp;
    String id;

    public PlaceCheckin(String checkinId) {
        id = checkinId;
    }
}
