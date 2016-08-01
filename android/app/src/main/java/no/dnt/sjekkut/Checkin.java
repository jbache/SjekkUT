package no.dnt.sjekkut;

import java.util.Date;

/**
 * Copyright Den Norske Turistforening 2015
 *
 * Created by espen on 09.02.2015.
 */
public class Checkin {

    public static class Statistics {
        int personalCount;
        int dailyCount;
        int totalCount;
    }

    Date timestamp;
    String mountain;
    long mountainId;
    Statistics statistics;
}
