package no.dnt.sjekkut.network;

import java.util.Date;
import java.util.List;

/**
 * Created by espen on 21.05.2015.
 */
public class Challenge {

    public String title;
    public String url;
    public String logoUrl;
    public String footerUrl;
    public List<Long> mountains;
    public Date validFrom;
    public Date validTo;
    public long id;
    public boolean joined;
    public int userProgress;
}
