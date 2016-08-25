package no.dnt.sjekkut.network;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 03.08.2016.
 */
public class MemberData {
    public String fornavn;
    public String etternavn;
    public String sherpa_id;
    public String epost;

    public String getFullname() {
        return String.format("%s %s", fornavn, etternavn);
    }
}
