package no.dnt.sjekkut.network;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

/**
 * Copyright Den Norske Turistforening 2016
 * <p>
 * Created by espen on 11.08.2016.
 */
public enum GsonSingleton {
    INSTANCE;

    private final Gson custom = new GsonBuilder()
            .registerTypeAdapter(Place.class, new PlaceDeserializer())
            .create();

    private final Gson plain = new GsonBuilder()
            .create();


    public static Gson custom() {
        return INSTANCE.custom;
    }

    public static Gson plain() {
        return INSTANCE.plain;
    }
}
