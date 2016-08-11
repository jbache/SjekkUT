package no.dnt.sjekkut.network;

import java.util.List;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 10.08.2016.
 */
public class Place {
    public String _id;
    public String navn;
    public String beskrivelse;
    public List<Photo> bilder;

    public Place(String _id) {
        this._id = _id;
    }
}
