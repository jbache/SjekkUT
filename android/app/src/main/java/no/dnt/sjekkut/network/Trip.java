package no.dnt.sjekkut.network;

import java.util.List;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 09.08.2016.
 */
public class Trip {
    public String _id;
    public String navn;
    public String beskrivelse;
    public List<Place> steder;
    public List<Photo> bilder;
}
