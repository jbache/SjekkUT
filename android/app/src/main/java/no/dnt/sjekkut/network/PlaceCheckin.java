package no.dnt.sjekkut.network;

import com.google.gson.JsonObject;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public class PlaceCheckin {
    String id;
    public String dnt_user_id;
    public String ntb_steder_id;
    String timestamp;
    JsonObject location;
}
