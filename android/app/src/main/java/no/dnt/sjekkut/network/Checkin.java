package no.dnt.sjekkut.network;

import java.util.Date;

/**
 * Copyright Den Norske Turistforening 2015
 *
 * Created by espen on 09.02.2015.
 */
public class Checkin {

    public static class Statistics {
        public int personalCount;
        public int dailyCount;
        public int totalCount;
    }

    public Date timestamp;
    public String mountain;
    public long mountainId;
    public Statistics statistics;
}
